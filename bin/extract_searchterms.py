import argparse
import json
import logging
import os
import sys
from argparse import Namespace
from datetime import datetime
from time import sleep
from urllib.parse import quote, unquote

import requests
from dateutil.relativedelta import relativedelta

MAPP_URL = os.environ['MAPP_URL']
MAPP_USER = os.environ['MAPP_USER']
MAPP_PW = os.environ.get('MAPP_PW')

def get_token(user: str, password: str)-> str:
    '''Get an access token from Mapp for a given user and password.'''
    url = os.path.join(MAPP_URL, "analytics/api/oauth/token")
    querystring = {
        'grant_type': 'client_credentials',
        'scope': 'mapp.intelligence-api'
    }
    try:
        response = requests.request("POST", url, auth=(user, password), params=querystring)
    except requests.exceptions.RequestException as e:
        logging.error(f" Failed to connect and authorize: {e}")
        sys.exit(1)

    # something went wrong
    if response.status_code != 200:
        logging.error(f" Autorization returned {str(response)}")
        sys.exit(1)

    # get the token (make a dictionary using json, then extract the actual token)
    values = json.loads(response.text)
    return values["access_token"]

def run_analysis_query(query: str, token: str) -> dict:
    '''Call the `analysis-query` endpoint with the `query`. Authorize with `token`.'''
    
    url = os.path.join(MAPP_URL, 'analytics/api/analysis-query')
    headers = {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
    }

    # request the query
    # - if the response contains "resultUrl" then it's complete already
    # - if the response contains "statusUrl" then we need to call that to check back when it is finished
    try:

        response = requests.request("POST", url, data=payload, headers=headers)
        if response.status_code > 201:
            logging.error(f" Call to analysis-query failed: {response}")
            exit()
        # unpack the response
        values = json.loads(response.text)

        resultUrl = values.get('resultUrl', False)
        statusUrl = values.get('statusUrl', False)
        while not resultUrl:
            sleep(0.5)
            logging.info(f" calling {statusUrl}")
            # call the status URL, and refresh the values of the URLs
            response = requests.request("GET", statusUrl, headers=headers)
            values = json.loads(response.text)
            resultUrl = values.get('resultUrl', False)

        logging.info(f" we have a result at {resultUrl}")
        response = requests.request("GET", resultUrl, headers=headers)
        data = json.loads(response.text)
    except requests.exceptions.RequestException as e:
        # something went wrong
        logging.error(f" Failed to retrieve analysis: {e}")
        sys.exit(1)

    return data

def time_range_for_month(month: str) -> tuple[str, str]:
    '''Return the start and end time of a time range defined by a year-month (YYYY-MM).'''
    # Parse the input string to a datetime object
    try:
        start_date = datetime.strptime(month, "%Y-%m")
    except ValueError as e:
        logging.error(" --month must be either YYYY-MM or 'previous'.")
        sys.exit(1)

    # Calculate the first day of the next month
    # If it's December, move to the next January of the following year
    if start_date.month == 12:
        next_month_date = datetime(start_date.year + 1, 1, 1)
    else:
        next_month_date = datetime(start_date.year, start_date.month + 1, 1)
    
    # Format both dates to the desired string format
    start_str = start_date.strftime("%Y-%m-%d %H:%M:%S")
    next_month_str = next_month_date.strftime("%Y-%m-%d %H:%M:%S")
    
    return start_str, next_month_str

def last_month_filter(time_filter: dict) -> dict:
    '''Take an incomplete time_filter dict and add the settings necessary 
       for a time_dynamic+last_month filter.'''
    time_filter['name'] = 'time_dynamic'
    time_filter['filterPredicate'] = 'LIKE'
    time_filter['value1'] = 'last_month'
    time_filter['value2'] = ''
    return time_filter

def time_filter_for_month(time_filter: dict, month: str) -> dict:
    '''Take an incomplete time_filter dict and add the settings necessary 
       for a time_range+month filter.'''
    start_date, end_date = time_range_for_month(month)
    time_filter['name'] = 'time_range'
    time_filter['filterPredicate'] = 'BETWEEN'
    time_filter['value1'] = start_date
    time_filter['value2'] = end_date
    return time_filter

def load_json_file(parameter: str, args: Namespace) -> dict:
    '''Load a json file from `file_path` for `parameter`.'''
    path = getattr(args, parameter)
    logging.info(f" loading {parameter} data from {path} ...")
    if os.path.isfile(path):
        config_file = open(path)
        config = json.load(config_file)
    else:
        logging.error(f" --{parameter} must be a filepath.")
        sys.exit(1)
    return config

logging.basicConfig(level=logging.INFO)

default_month = 'previous'
default_conf_path = 'conf/conf.json'
default_blocklist_path = 'conf/blocklist.json'
default_out_path = 'data/temp/daten_berlin_de.searchterms.unfiltered.json'

parser = argparse.ArgumentParser(description="Extract the dataset searchterms from daten.berlin.de for a given month.")
parser.add_argument('-m', '--month', default=default_month,
                    help=f"The year-month in IS8601 (YYYY-MM) for which to extract the searchterms. Default is '{default_month}'.")
parser.add_argument('-c', '--config', default=default_conf_path,
                    help=f"The path to the JSON config file defining the query to Mapp. Default is {default_conf_path}.")
parser.add_argument('-b', '--blocklist', default=default_blocklist_path,
                    help=f"The path to the JSON file containing the blocklist of searchterms to ignore. Default is {default_blocklist_path}.")
parser.add_argument('-o', '--outfile', default=default_out_path,
                    help=f"The path to the output JSON file. Default is {default_out_path}.")
args = parser.parse_args()

config = load_json_file("config", args)
blocklists = load_json_file("blocklist", args)
blocklist_flat = sorted({term for blocklist in blocklists.values() for term in blocklist})
out_data = load_json_file("outfile", args)

time_filter = {
    "connector": "AND",
    "context": "NONE",
    "caseSensitive": False
}

month = args.month
if month == 'previous':
    now = datetime.now()
    previous_month = now - relativedelta(months=1)
    month = previous_month.strftime("%Y-%m")
    logging.info(f" 'previous' evaluated to {month}")

logging.info(f" adjusitng time filter to {month} ...")
time_filter = time_filter_for_month(time_filter, month)

filters = config["searchterms"]["queryObject"]["predefinedContainer"]["filters"]
filters.append(time_filter)

payload = json.dumps(config["searchterms"])
logging.info(" query defined ...")
if not MAPP_PW:
    try:
        import keyring
    except ImportError:
        logging.error(" could not import 'keyring', and MAPP_PW is not set")
        sys.exit(1)
    MAPP_PW = keyring.get_password('mapp_api', MAPP_USER)
token = get_token(MAPP_USER, MAPP_PW)
logging.info(" token received ...")
data = run_analysis_query(payload, token)
logging.info(" query run ...")

term_list = data['rows']
terms_dict = {}

blocked_terms = [term for term in term_list if unquote(term[0]) in blocklist_flat]
term_list = [term for term in term_list if unquote(term[0]) not in blocklist_flat]

month_dict = {}
for term in term_list:
    term_dict = {
        "impressions": term[2],
        "visits": term[1],
        "page_duration_avg": float("{:.2f}".format(term[3])),
        "exit_rate": float("{:.2f}".format(term[4]))
    }
    terms_dict[term[0]] = term_dict
month_dict['terms'] = terms_dict
month_dict['removed_items'] = {
    "comment": f"Removed {len(blocked_terms)} searchterms as potentially personal information.",
    "count": len(blocked_terms)
}

out_data['timestamp'] = datetime.isoformat(datetime.now())
out_data['stats']['months'][month] = month_dict

out_data['stats']['months'] = {k: out_data['stats']['months'][k] for k in sorted(out_data['stats']['months'], reverse=True)}

months = sorted(list(out_data['stats']['months'].keys()))
earliest = months[0]
latest = months[-1]

out_data['stats']['earliest'] = earliest
out_data['stats']['latest'] = latest

out_json = json.dumps(out_data, indent=2, ensure_ascii=False)
logging.info(f" writing output to {args.outfile} ...")
with open(args.outfile, 'w') as output:
    output.write(out_json)

