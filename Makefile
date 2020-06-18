# all: stats compress README.pdf

# stats:
# 	@echo "generate stats"
# 	@ruby bin/extract_stats.rb conf/conf.json ${OUT_FOLDER}

# compress:
# 	@echo "compress daten_berlin_de.stats.json.tgz"
# 	@rm -f ${OUT_FOLDER}/daten_berlin_de.stats.json.tgz
# 	@tar -cvzf ${OUT_FOLDER}/daten_berlin_de.stats.json.tgz ${OUT_FOLDER}/daten_berlin_de.stats.json

final: data/target/daten_berlin_de.searchterms.json
data/target/daten_berlin_de.searchterms.json: data/temp/daten_berlin_de.searchterms.filtered.json
	@echo "building final version ..."
	@echo "writing to $@ ..."
	@cp $< $@

data/target/daten_berlin_de.searchterms.%.csv:
	@echo "converting to CSV ..."
	@echo "writing to $@ ..."
	@bin/csv_for.sh data/target/daten_berlin_de.searchterms.json $@

filtered: data/temp/daten_berlin_de.searchterms.filtered.json
data/temp/daten_berlin_de.searchterms.filtered.json: data/temp/daten_berlin_de.searchterms.unfiltered.json conf/blocklist.json conf/allowlist.json
	@echo "filtering $< for personal data, applying $(word 2,$^) ..."
	@echo "writing to $@ ..."
	@ruby bin/filter_searchterms.rb $< $@ data/temp/rejected.csv $(word 2,$^) $(word 3,$^)

unfiltered: data/temp/daten_berlin_de.searchterms.unfiltered.json
.PHONY: data/temp/daten_berlin_de.searchterms.unfiltered.json
data/temp/daten_berlin_de.searchterms.unfiltered.json: data/temp
	@echo "extracting search terms ..."
	@echo "writing to $@ ..."
	@ruby bin/extract_searchterms.rb conf/conf.json $@
 
README.pdf: README.md
	@echo "generate README.pdf from README.md"
	@pandoc -o README.pdf README.md

.PHONY: README.md
README.md: data/temp/date.txt
	@echo "update README.md with current date"
	@sed '$$ d' README.md > _README.md
	@cat _README.md $< > README.md
	@rm _README.md

data/temp/terms_%.json:
	@echo "extracting list of searchterms from data/temp/daten_berlin_de.searchterms.unfiltered.json ..."
	@echo "writing to $@ ..."
	@bin/terms_for.sh data/temp/daten_berlin_de.searchterms.unfiltered.json $@

.PHONY: data/temp/date.txt
data/temp/date.txt: | data/temp
	@echo "write current date ..."
	@date "+Last changed: %Y-%m-%d" > $@

clean: clean-temp

clean-temp:
	@echo "deleting temp folder ..."
	@rm -rf data/temp

data/temp:
	@echo "creating temp directory ..."
	@mkdir -p data/temp

