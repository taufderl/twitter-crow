import numpy as np
from sklearn.cluster import DBSCAN
import fileinput
import json

##############################################################################
# Load Tweet data

jsondata = json.loads(fileinput.input()[0])
X = np.array(jsondata['data'])
IDs = jsondata['ids']

##############################################################################
# Compute DBSCAN
#db = DBSCAN(eps=0.3, min_samples=10).fit(X)
db = DBSCAN(eps=0.3, min_samples=10).fit(X)
core_samples = db.core_sample_indices_
labels = db.labels_

# Number of clusters in labels, ignoring noise if present.
n_clusters_ = len(set(labels)) - (1 if -1 in labels else 0)

##############################################################################
# Return labels
print(json.dumps(labels.tolist()))

