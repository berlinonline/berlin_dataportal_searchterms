import json
import sys
from urllib.parse import unquote

unquoted_list = []
with open(sys.argv[1]) as term_data:
    term_list = json.load(term_data)
    for term in term_list:
        unquoted_list.append(unquote(term))

print(json.dumps(unquoted_list, ensure_ascii=False, indent=2))
