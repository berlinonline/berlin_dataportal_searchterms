# daten.berlin.de Searchterms

![logo for "daten.berlin.de searchterms" dataset](logo/searchterms-logo_complete_small.png)

This dataset contains the searchterms that users looked for on the Berlin Open Data Portal (https://daten.berlin.de).
Terms are collected per month (starting in February 2019, when we started using our new analytics software), and ranked by how often they were searched (i.e., the number of page impressions).

## Requirements

The code to extract the searchterm statistics is written in Ruby.
It has been tested with Ruby 2.7.1.

The required gems are defined in the [Gemfile](Gemfile). In particuler, these are:

- [webtrekk_connector](https://rubygems.org/gems/webtrekk_connector)
- [ruby-keychain](https://rubygems.org/gems/ruby-keychain)

If you have [bundler](https://bundler.io), you can install the required gems as follows:

```
bundle install
```

## daten_berlin_de.searchterms.json

For each searchterm that was entered in a given month, the page impressions, visits, average page duration (in seconds) and exit rate (%) are listed. 

The following example illustrates the structure of the data file:

```json
{
  "timestamp": "2020-05-29T15:21:32+02:00",
  "source": "Webtrekk",
  "stats": {
    "site_uri": "daten.berlin.de",
    "earliest": "2019-02",
    "latest": "2020-04",
    "months": {
      "2020-04": {
        "terms": {
          "corona": {
            "impressions": 27,
            "visits": 20,
            "page_duration_avg": 36.81,
            "exit_rate": 20.0
          },
          "verkehr": {
            "impressions": 24,
            "visits": 8,
            "page_duration_avg": 38.08,
            "exit_rate": 0.0
          },
          ...
          "new york": {
            "impressions": 1,
            "visits": 1,
            "page_duration_avg": 0.0,
            "exit_rate": 0.0
          }
        },
        "removed_items": {
          "comment": "Removed 13 searchterms as potentially personal information.",
          "count": 13
        }
      },
      "2020-03": {
          ...
      },
      ...
    }
  }
}
```

## Filtering Personal Information

All searchterms that potentially contain personal information are removed from the data before publishing it here.

In particular, the following categories of searchterms are removed:

- personal names
- (postal) addresses
- geographic coordinates
- personal e-mail adresses
- phone numbers
- land lots (German „Flurstück“)

### Blacklist

Instances of these categories are currently not detected automatically, but rather manually via the use of a blacklist (not included in this repository), which is being extended each time the dataset is updated (i.e., every month).

### Whitelist

There are exceptions where searchterms are included in the data, even though they belong to one of the exclusion categories.
In particular, we allow the following kinds of searchterms:

- **Personal names of public figures**\
The criterion for being a public figure is: there is a (stable) Wikipedia page for that person.
The criteria for people to have Wikipedia page are defined [here](https://en.wikipedia.org/wiki/Wikipedia:Notability_(people) "Definition of notability for people on Wikipedia").\
Another possible criterion is that a name has an entry in a bibliographic [authority file](https://en.wikipedia.org/wiki/Authority_control) (something like a database of all known authors), such as the [Gemeinsame Normdatei](https://www.dnb.de/EN/Professionell/Standardisierung/GND/gnd_node.html).
In other words, a name is the name of a published author.
- **Functional e-mail addresses**\
Functional e-mail addresses (addresses not tied to a particular person, but to a role or a post such as `info@example.com`, `opendata@berlin.de` etc.) do not contain personal information and can therefore be included.

## Searchterm Normalization

Searchterms are currently not normalized in any way.
This means that different spellings of the same term (most importantly: differences in case) are treated as different searchterms.
It is possible to sum page impressions for each term.
This is not possible for visits, because the same visit might be include two or more searchterms, and so the actual number of visits for a set of searchterms might be less than the sum of visits for all of them.

For example:

```json
{
...
  "terms": {
    "corona": {
      "impressions": 27,
      "visits": 20,
      "page_duration_avg": 36.81,
      "exit_rate": 20.0
    },
    ...
    "Corona": {
      "impressions": 8,
      "visits": 6,
      "page_duration_avg": 21.25,
      "exit_rate": 0.0
    },
    ...
    "covid": {
      "impressions": 2,
      "visits": 2,
      "page_duration_avg": 13.0,
      "exit_rate": 0.0
    },
...
}
```

People searched for `corona` (lower case), `Corona` (upper case), `covid` and possibly other related searchterms.
It would be valid to say that the total number of page impressions for all spellings of `corona` is `27+8=35`, and `27+8+2=37` for all Corona-related searches.
However, the total number of visits for all spellings of `corona` is `20+6=26` _or less_ because some of these searches may have occured within the same visit.

## Logo

- [search](https://fontawesome.com/icons/search) logo by [FontAwesome](https://fontawesome.com) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## License

All software in this repository is published under the [MIT License](LICENSE).
All data in this repository (in particular the `.json` files) is published under [CC BY 3.0 DE](https://creativecommons.org/licenses/by/3.0/de/).

---

Dataset URL: [https://daten.berlin.de/datensaetze/suchbegriffe-datenberlinde](https://daten.berlin.de/datensaetze/suchbegriffe-datenberlinde)

This page was generated from the github repository at [https://github.com/berlinonline/berlin_dataportal_searchterms](https://github.com/berlinonline/berlin_dataportal_searchterms).

2020, Knud Möller, [BerlinOnline Stadtportal GmbH & Co. KG](https://www.berlinonline.net)

Last changed: 2020-06-02
