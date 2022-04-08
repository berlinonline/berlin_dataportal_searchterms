from datetime import date, timedelta
import json
import logging
from berlinonline.ckan_metadata_updater import CKANMetadataUpdater

def update_temporal_coverage_to(dataset_metadata: dict):
    # calculate the last day of the previous month
    today = date.today()
    first = today.replace(day=1)
    lastMonth = (first - timedelta(days=1)).isoformat()
    logging.info(f" setting `temporal_coverage_to` to {lastMonth}")
    dataset_metadata['temporal_coverage_to'] = lastMonth
    return dataset_metadata

updater = CKANMetadataUpdater()
updater.steps.append({
    "function": update_temporal_coverage_to,
    "parameters": []
})
updater.run()
