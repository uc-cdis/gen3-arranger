#!/bin/bash
#
# Source this file to pickup some helper functions
#

export ESHOST=${ESHOST:-"localhost:9200"}
export ESHOST=esproxy-service:9200

#
# Delete all the indexes out of ES that grep-match a given string
# @param grepStr defaults to match everything
#
function es_delete_all() {
  local grepStr
  local indexList
  grepStr=$1
  if [[ -n "$grepStr" ]]; then
    indexList=$(es_indices 2> /dev/null | awk '{ print $3 }' | grep "$grepStr")
  else
    indexList=$(es_indices 2> /dev/null | awk '{ print $3 }')
  fi
  for name in $indexList; do
    curl -iv -X DELETE "${ESHOST}/$name"
  done
}

function es_port_forward() {
g3kubectl port-forward deployment/aws-es-proxy-deployment 9200
   
}

function es_port_forward_arranger() {
g3kubectl port-forward deployment/arranger-dashboard-deployment 6060 5050 &

}

function es_delete() {
  local name
  name="$1"
  if [[ -n "$name" ]]; then
    curl -iv -X DELETE "${ESHOST}/$name"
  else
    echo 'Use: es_delete INDEX_NAME'
  fi
}


#
# Little helper to create the ETL index
# with the qa-brain mapping
#
function es_setup_etl() {
curl -iv -X PUT "${ESHOST}/etl" \
-H 'Content-Type: application/json' -d'
{
    "mappings": {
      "case" : {
        "properties" : {
          "_aliquots_count" : {
            "type" : "long"
          },
          "_analytes_count" : {
            "type" : "long"
          },
          "_mri_images_count" : {
            "type" : "long"
          },
          "_read_groups_count" : {
            "type" : "long"
          },
          "_samples_count" : {
            "type" : "long"
          },
          "_submitted_expression_array_files_count" : {
            "type" : "long"
          },
          "_submitted_unaligned_reads_files_count" : {
            "type" : "long"
          },
          "alcohol_use_score" : {
            "type" : "keyword"
          },
          "childhood_trauma_diagnosis" : {
            "type" : "keyword"
          },
          "childhood_trauma_score" : {
            "type" : "keyword"
          },
          "depression_diagnosis" : {
            "type" : "keyword"
          },
          "depression_severity" : {
            "type" : "keyword"
          },
          "ethnicity" : {
            "type" : "keyword"
          },
          "experimental_group" : {
            "type" : "keyword"
          },
          "gender" : {
            "type" : "keyword"
          },
          "node_id" : {
            "type" : "text"
          },
          "project_id" : {
            "type" : "keyword"
          },
          "race" : {
            "type" : "keyword"
          },
          "submitter_id" : {
            "type" : "keyword"
          },
          "tbi_diagnosis" : {
            "type" : "keyword"
          },
          "total_tbi" : {
            "type" : "long"
          }
        }
      }
    }
}'

}


#
# Setup `subject` index for arranger-projects-dev project
#
function es_setup_index() {
curl -iv -X PUT "${ESHOST}/gen3-dev-subject" \
-H 'Content-Type: application/json' -d'
{
    "settings" : {
        "index" : {
            "number_of_shards" : 1, 
            "number_of_replicas" : 0 
        }
    },
    "mappings": {
      "subject": {
        "properties": {
          "name": { "type": "text" },
          "project": { "type": "keyword" },
          "study": { "type": "keyword" },
          "gender": { "type": "keyword" },
          "race": { "type": "keyword" },
          "ethnicity": { "type": "keyword" },
          "vital_status": { "type": "keyword" },
          "file_type": { "type": "keyword" },
          "file_format": { "type": "keyword" },
          "gen3_resource_path": { "type": "keyword" }
        }
      }
    }
}
'
}


#
# Dump the contents of a given index
#
# @parma indexName
#
function es_dump() {
  local indexName
  indexName=$1

curl -X GET "${ESHOST}/${indexName}/_search?pretty=true&size=100" \
-H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} }
}
'

}

#
# Get the list of indexes
#
function es_indices() {
  curl -X GET "${ESHOST}/_cat/indices?v"
}

#
# Dump the arranger config indexes to the given destination folder
# @param destFolder
# @param projectName name of the arranger project
#
function es_export() {
  local destFolder
  local projectName
  local indexList

  if [[ $# -lt 2 ]]; then
    echo 'USE: es_export destFolderPath arrangerProjectName'
    return 1
  fi
  destFolder="$1"
  shift
  projectName="$1"
  shift
  mkdir -p "$destFolder"
  indexList=$(es_indices 2> /dev/null | grep "arranger-$projectName" | awk '{ print $3 }')
  for name in $indexList; do
    echo $name
    npx elasticdump --input http://$ESHOST/$name --output ${destFolder}/${name}__data.json --type data
    npx elasticdump --input http://$ESHOST/$name --output ${destFolder}/${name}__mapping.json --type mapping
  done
}

#
# 
es_port_forward() {
  if ps uxwwww | grep port-forward | grep 9200 > 1>&2; then
    echo "It looks like a port-forward process is already running" 1>&2
    return 1
  fi
  local OFFSET
  OFFSET=$((RANDOM % 1000))
  g3kubectl port-forward deployment/aws-es-proxy-deployment $((OFFSET+9200)):9200
  export ESHOST="localhost:$((OFFSET + 9200))"
  echo "ESHOST=$ESHOST" 1>&2
}

#
# Import the arranger config indexes dumped with es_export
# @param sourceFolder with the es_export files
# @param projectName name of the arranger project to import
#
function es_import() {
  local sourceFolder
  local projectName
  local indexList

  if [[ $# -lt 2 ]]; then
    echo 'USE: es_import srcFolderPath arrangerProjectName'
    return 1
  fi

  sourceFolder="$1"
  shift
  projectName="$1"
  shift
  #indexList="$(es_indices 2> /dev/null | grep arranger- | awk '{ print $3 }')"
  indexList=$(ls -1 $sourceFolder | sed 's/__.*json$//' | grep "arrangerr-$projectName" | sort -u)
  for name in $indexList; do
    echo $name
    npx elasticdump --output http://$ESHOST/$name --input $sourceFolder/${name}__data.json --type data
    npx elasticdump --output http://$ESHOST/$name --input $sourceFolder/${name}__mapping.json --type mapping
  done
  
  # make sure arranger-projects index has an entry for our project id
  curl -X PUT $ESHOST/arranger-projects/arranger-projects/$projectName?pretty=true \
    -H 'Content-Type: application/json' -d'
      {
        "_index" : "arranger-projects",
        "_type" : "arranger-projects",
        "_id" : "brain",
        "_score" : 1.0,
        "_source" : {
          "id" : "brain",
          "active" : true,
          "timestamp" : "2018-08-28T18:58:53.452Z"
        }
';
}

#
# Get the mapping of a given index
#
function es_mapping() {
  local indexName
  indexName=$1
  curl -X GET $ESHOST/${indexName}/_mapping?pretty=true
}

#
# Generate test data in gen3-dev-subject index
#
function es_gen_data() {
  local startIndex
  local endIndex
  local COUNT
  local tmpName
  startIndex="${1:-0}"
  endIndex="${2:-0}"

declare -a genderList
declare -a ethnicityList
declare -a raceList
declare -a vitalList
declare -a fileTypeList
declare -a fileFormat

genderList=( male female )
ethnicityList=( 'American Indian' 'Pacific Islander' 'Black' 'Multi-racial' 'White' 'Haspanic' )
raceList=( white black hispanic asian mixed )
vitalList=( Alive Dead )
fileTypeList=( "mRNA Array" "Unaligned Reads" "Lipdomic MS" "Protionic MS" "1Gs Ribosomes")
fileFormatList=( BEM BAM BED CSV FASTQ RAW TAR TSV TXT IDAT )

COUNT=$startIndex
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
tmpName="$(mktemp $XDG_RUNTIME_DIR/es.json.XXXXXX)"
while [[ $COUNT -lt $endIndex ]]; do
  projectIndex=$(( $RANDOM % 5 ))
  projectName="Proj-${projectIndex}"
  if [[ $projectIndex == 0 ]]; then
    # dev environments have a test project
    projectName="test"
  fi
  studyIndex=$(( $RANDOM % 10 ))
  gender="${genderList[$(( $RANDOM % ${#genderList[@]}))]}"
  ethnicity="${ethnicityList[$(( $RANDOM % ${#ethnicityList[@]}))]}"
  race="${raceList[$(( $RANDOM % ${#raceList[@]}))]}"
  vital="${vitalList[$(( $RANDOM % ${#vitalList[@]}))]}"
  fileType="${fileTypeList[$(( $RANDOM % ${#fileTypeList[@]}))]}"
  fileFormat="${fileFormatList[$(( $RANDOM % ${#fileFormatList[@]}))]}"

  cat - > "$tmpName" <<EOM
{
  "name": "Subject-$COUNT",
  "project": "${projectName}",
  "study": "Study-${projectIndex}${studyIndex}",
  "gender": "${gender}",
  "ethnicity": "${ethnicity}",
  "race": "${race}",
  "vital_status": "${vital}",
  "file_type": "${fileType}",
  "file_format": "${fileFormat}",
  "gen3_resource_path": "/projects/$projectName"
}
EOM
  cat - $tmpName <<EOM
Loading record:
EOM
  curl -X PUT "${ESHOST}/gen3-dev-subject/subject/${COUNT}?pretty" \
       -H 'Content-Type: application/json' "-d@$tmpName"

  let COUNT+=1
done
}

#--------------------------
# GraphQL queries

if false; then

curl -X GET "${ESHOST}/arranger-projects-dev-gen3-dev-subject/_search" \
-H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} }
}
'

COUNT=0
while [[ $COUNT -lt 2 ]]; do
  curl -X POST "${ESHOST}/arranger-projects-dev/arranger-projects-dev/${COUNT}/_update?pretty" -H 'Content-Type: application/json' -d"
{ \"doc\": {
  \"id\": $COUNT,
  \"name\": \"A$COUNT\",
  \"count\": $COUNT
}}
"

  let COUNT+=1
done


#----------------------------------
# graphQL queries
#    Looking for fields on type, got: mapping,extended,aggsState,columnsState,matchBoxState,hits,aggregations subject
#
curl  -X POST localhost:3000/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ subject { __typename } }"
}
'

curl  -X POST https://qa-brain.planx-pla.net/api/v0/flat-search/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ etl { __typename } }"
}
'

curl  -X POST localhost:3000/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ subject { __typename, mapping, hits {total, edges{ node{name, project, study} } }  } }"
}
'

curl  -X POST https://abby.planx-pla.net/api/v0/flat-search/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ subject { __typename, mapping, hits {total, edges{ node{name, project, study} } }  } }"
}
'

curl  -X POST https://qa-brain.planx-pla.net/api/v0/flat-search/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ subject { __typename, mapping, hits {total, edges{ node{name, project, study} } }  } }"
}
'

curl  -X POST https://qa-brain.planx-pla.net/api/v0/flat-search/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ etl { __typename, mapping, hits {total, edges{ node{gender, race} } }  } }"
}
'

curl  -X POST https://abby.planx-pla.net/api/v0/flat-search/search/graphql \
-H 'Content-Type: application/json' -d'
{
"query":"query subject($sqon: JSON, $include_missing: Boolean) { 
  subject { 
    hits( filters: $sqon) { total }
    aggregations(filters: $sqon, include_missing: $include_missing) {
      size {
        stats {
          sum
        }
      }
    }
  }
}",
"variables": "{
  sqon: {
    op: "and",
    content: [
      {
        op: "in",
        content: {
          field: "gender",
          value: "famale"
        }
      }
    ]
  },
  include_missing: true
}"
';

curl  -X POST https://abby.planx-pla.net/api/v0/flat-search/search/graphql \
-H 'Content-Type: application/json' -d'
{
"query":"query subject($sqon: JSON, $include_missing: Boolean) { subject { hits( filters: $sqon) { total } aggregations(filters: $sqon, include_missing: $include_missing) {}",
"variables": "{ sqon: {}, include_missing: true }"
';


# 'query { subject { hits{ edges{ node {name} } } }'
# result: {"data":{"subject":{"__typename":"subject","mapping":{"count":{"type":"integer"},"name":{"type":"text"}},"hits":{"total":2,"edges":[{"node":{"name":"A0","count":0}},{"node":{"name":"A1","count":1}}]}}}}



tmpName=frickjack.json
cat - > "$tmpName" <<EOM
{
  "timestamp" : "2018-08-28T19:14:25.787Z",
  "state" : [
    {
      "field" : "_aliquots_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "_analytes_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "_mri_images_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "_read_groups_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "_samples_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "_submitted_expression_array_files_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "_submitted_unaligned_reads_files_count",
      "show" : false,
      "active" : true
    },
    {
      "field" : "alcohol_use_score",
      "show" : false,
      "active" : true
    },
    {
      "field" : "childhood_trauma_diagnosis",
      "show" : false,
      "active" : true
    },
    {
      "field" : "childhood_trauma_score",
      "show" : false,
      "active" : true
    },
    {
      "field" : "depression_diagnosis",
      "show" : false,
      "active" : true
    },
    {
      "field" : "depression_severity",
      "show" : false,
      "active" : true
    },
    {
      "field" : "ethnicity",
      "show" : false,
      "active" : true
    },
    {
      "field" : "experimental_group",
      "show" : false,
      "active" : true
    },
    {
      "field" : "gender",
      "show" : false,
      "active" : true
    },
    {
      "field" : "project_id",
      "show" : false,
      "active" : true
    },
    {
      "field" : "race",
      "show" : false,
      "active" : true
    },
    {
      "field" : "submitter_id",
      "show" : false,
      "active" : true
    },
    {
      "field" : "tbi_diagnosis",
      "show" : false,
      "active" : true
    },
    {
      "field" : "total_tbi",
      "show" : false,
      "active" : true
    }
  ]
}
EOM

  cat - $tmpName <<EOM
Loading record:
EOM

curl -X POST "${ESHOST}/arranger-projects-brain-etl-aggs-state/arranger-projects-brain-etl-aggs-state/0e9f1c1a-c361-42e2-b3c2-3ee220ebd91a?pretty" \
       -H 'Content-Type: application/json' "-d@$tmpName"


curl -X POST "${ESHOST}/arranger-projects"

fi
