[![Build Status](https://travis-ci.org/nansencenter/django-geo-spaas-rest-api.svg?branch=master)](https://travis-ci.org/nansencenter/django-geo-spaas-rest-api) [![Coverage Status](https://coveralls.io/repos/github/nansencenter/django-geo-spaas-rest-api/badge.svg?branch=master)](https://coveralls.io/github/nansencenter/django-geo-spaas-rest-api?branch=master)
# REST API for django-geo-spaas

`geospaas_rest_api` is a Django application which provides a REST API for the [GeoSPaaS application](https://github.com/nansencenter/django-geo-spaas).


## Implementation

This API is based on [Django REST framework](https://www.django-rest-framework.org/).


## Functionalities

### GeoSPaaS data access

This API provides endpoints to list the following objects stored in a GeoSPaaS database:
  - geographic_locations
  - sources
  - instruments
  - platforms
  - people
  - roles
  - datasets
  - parameters
  - dataset_uris
  - dataset_relationships
  - datacenters

Each of these endpoints can be appended to the API root URL to get a list of the objects
it represents.  
For example, `https://<api_root_url>/datasets` returns a paginated list of the datasets present
in the database.

Objects can be also be accessed by id: `https://<api_root_url>/sources/2` returns the
JSON representation of the source which id is 2.
Django REST framework provides a browsable API, so all this data can be visualized and explored
in a browser, in JSON format.

Basic dataset filtering capabilities are implemented. It is possible to filter datasets based on 
date, location and source. See the **[Searching for datasets](#searching-for-datasets)** section.


### Processing

The `/jobs/` endpoint offers the ability to trigger processing tasks based on GeoSPaaS data.

For now, the only available operation is downloading datasets to the server where the API is
running.
Then, they can then be made available via FTP, for example.


## Data representation

The API endpoints reflect the structure of the database of the GeoSPaaS application.
Relations between objects are implemented using the `id` property of the objects.

For example, the following dataset JSON representation, the
`ISO_topic_category`, `data_center`, `source`, `geographic_location` and `gcmd_location` fields
contain the id of the objects related to the dataset.

```json
# GET <api_root>/datasets/365/
{
    "id": 365,
    "entry_id": "efbab004-4a70-454a-9498-3d6fef13d6b4",
    "entry_title": "VIIRS L2P SST",
    "summary": "Sea surface temperature retrievals produced by NOAA/NESDIS/STAR office from VIIRS sensor",
    "time_coverage_start": "2018-02-09T00:10:01Z",
    "time_coverage_end": "2018-02-09T00:19:59Z",
    "access_constraints": null,
    "ISO_topic_category": 1,
    "data_center": 3,
    "source": 3,
    "geographic_location": 365,
    "gcmd_location": 1,
    "parameters": []
}
```

The related objects can be accessed through their respective endpoints.  
For example, to get the location covered by this dataset:

```json
# GET <api_root>/geographic_locations/365/
{
    "id": 365,
    "geometry": "SRID=4326;POLYGON ((-153.13 34.948, -147.554 0.552, -174.438 -3.507, 174.988 30.162, -153.13 34.948))"
}
```


## Searching for datasets

Datasets can be filtered by date, location and source.

These search parameters can be used simultaneously. In that case, the result is equivalent to a
logical `and` between all the conditions.

All search parameters containing special characters should be URL-encoded.
If you use the browsable API, your browser usually takes care of that.

### Filtering by date

To filter by date, add the `date` parameter to your GET request to the `datasets` endpoint.
The request will return all datasets for which the provided date is comprised in the time range
covered by the dataset.

The value can be:
  - a date in a format readable by the [dateutil](https://dateutil.readthedocs.io/en/stable/)
    Python package, for example `2017-05-18T00:00:00Z`.
  - a couple of such dates defining a time range, for example
    `(2017-05-18T00:00:00Z, 2017-05-19T00:00:00Z)`

The search is inclusive. For example:
  - a search using `date=2017-05-18T00:00:00Z` will include the datasets for which
    `time_coverage_start` or `time_coverage_end` is equal to `2017-05-18T00:00:00Z`.
  - a search using `date=(2017-05-18T00:00:00Z, 2017-05-19T00:00:00Z)` will include datasets 
    for which `time_coverage_start` = `2017-05-19T00:00:00Z` as well as those
    for which `time_coverage_end` = `2017-05-18T00:00:00Z`.

The full URL to filter the datasets with the previous example would be:

`https://<api_root_url>/datasets?date=2017-05-18T00%3A00%3A00Z`

If the time zone is not specified, it is assumed to be UTC.

### Filtering by location

To filter by location, add the `zone` parameter to your GET request to the `datasets` endpoint.
The request will return all datasets for which the provided zone intersects with the geospatial
location covered by the dataset.

The value should be a WKT representation of the searched zone, URL-encoded if provided in the URL.

For example, if the WKT string is `POINT(17.55 78.78)`, the URL would be:

`https://<api_root_url>/datasets?zone=POINT%2817.55+78.78%29`

> *Crossing the international date line:*
>
> If you need to search using a polygon which crosses the international date line, you can use
> longitudes outside the [-180, 180] range.
>
> Here is an example for more clarity:  
> Let us imagine that we are looking for two datasets which spatial coverage is respectively
> `POLYGON((173 -17,174 -17,174 -20,173 -20,173 -17))` and
> `POLYGON((-173 -17,-174 -17,-174 -20,-173 -20,-173 -17))`.  
> `POLYGON((170 -18,190 -18,190 -19,170 -19,170 -18))` intersects both those datasets and can be
> used to search for them.  
> On the other hand, `POLYGON((170 -18,-170 -18,-170 -19,170 -19,170 -18))` does not intersect
> either of these datasets.

### Filtering by source

To filter by source, add the `source` parameter to your GET request to the `datasets` endpoint.
The request will return all datasets for which the provided source is contained in the dataset's
source's name (which is a concatenation of the `platform` and `instrument` properties of the source,
separated by an underscore).

The value should be a string. The matching is case-insensitive.

For example:

- `https://<api_root_url>/datasets?source=viirs` gets all VIIRS datasets
- `https://<api_root_url>/datasets?source=npp_viirs` gets all VIIRS datasets from the NPP platform
- `https://<api_root_url>/datasets?source=n20_viirs` gets all VIIRS datasets from the N20 platform


## Triggering jobs

### Implementation

Long running jobs are implemented in
[geospaas_processing](https://github.com/nansencenter/django-geo-spaas-processing).
It is based on the
[Celery](https://docs.celeryproject.org/en/stable/getting-started/introduction.html) framework.

In `geospaas_processing`, Celery **tasks** are defined for diverse operations:
downloading, converting, archiving, etc...

Each job can be composed of one or more of these tasks. It provides a convenient way to check the
status of this task or series of tasks.

The API exposes these capabilities through the `/jobs/` endpoint.

### Usage

The `/jobs/` endpoint enables the user to trigger jobs and check their status.

A job is triggered by sending a POST request to the `/jobs/` endpoint, with data having the
following structure:

```json
{
    "action": "<action>",
    "parameters": {"<parameter1>": "<value1>", "<parameter2>": "<value2>"}
}
```

The parameters that need to be provided depend on the type of job.
The available actions and the associated parameters are described below.

The response will contain the following information about the job:
  - `id`: the ID of the job
  - `task_id`: the ID of the first task in the job
  - `date_created`: the date and time at which the job was created
  - `status`: the status of the job

Here is an example of the data contained in such a response:

```json
{
    "id": 4,
    "task_id": "b579fade-6cb5-4fba-9157-b8633a0910bc",
    "date_created":"2020-09-18T10:14:44.635370Z",
    "status":"STARTED"
}
```

The status of the job (and each of its tasks) can be:
  - `STARTED`: the job is currently executing
  - `SUCCESS`: the job finished successfully
  - `RETRY`: the job (or part of it) will be retried later, for example if is waiting for a lock
  - `FAILED`: the job failed

Further information about a job can be accessed by sending a GET request to:
`https://<api_root_url>/jobs/<job_id>/`.
This link can be polled as needed to get updates on the status of the job.

Continuing the previous example, a request to `https://<api_root_url>/jobs/4/` would yield
the following data:

```json
{
    "id": 4,
    "task_id": "b579fade-6cb5-4fba-9157-b8633a0910bc",
    "date_created": "2020-09-18T10:14:44.635370Z",
    "status": "SUCCESS",
    "date_done": "2020-09-18T10:14:47.139263Z",
    "result": "<task_result>"
}
```

Where `<task_result>` is the result of the last task in the job.

The `/tasks/` endpoint gives read-only access to the individual tasks for diagnostics purposes.

#### Available actions

The following actions are available on the `/jobs/` endpoint.

##### `download`

Downloads a dataset to the API server.

Payload:

```json
{
    "action": "download",
    "parameters": {"dataset_id": <dataset_id>}
}
```

Where `<dataset_id>` (integer) is the ID of the dataset to download.
It can be obtained using the search capabilities of the `/datasets/` endpoint.

Once the job is over, its **"result"** is set with a two-elements list.
  - the first element is the ID of the dataset that was downloaded
    (this enables to easily chain tasks together)
  - the second element is the link where the dataset can be retrieved.

##### `convert`

Converts a dataset file to a given format.

Payload:

```json
{
    "action": "convert",
    "parameters": {
      "format": "<format>",
      "dataset_id": <dataset_id>,
    }
}
```

Where:
  - `<format>` (string) is the target format.
  - `<dataset_id>` (integer) is the ID of the dataset to download.

Available formats:
  - "idf"

Once the job is over, its **"result"** is set with a two-elements list.
  - the first element is the ID of the dataset that was converted
    (this enables to easily chain tasks together)
  - the second element is the link where the converted file can be retrieved.
