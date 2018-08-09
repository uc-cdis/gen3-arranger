#!/bin/bash
#
# Source this file to pickup some helper functions
#

export ESHOST=${ESHOST:-"localhost:9200"}

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

curl -X GET "${ESHOST}/${indexName}/_search?pretty=true" \
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
#
function es_export() {
  local destFolder
  local indexList

  destFolder="$1"
  mkdir -p "$destFolder"
  indexList=$(es_indices 2> /dev/null | grep arranger- | awk '{ print $3 }')
  for name in $indexList; do
    echo $name
    npx elasticdump --input http://$ESHOST/$name --output ${destFolder}/${name}__data.json --type data
    npx elasticdump --input http://$ESHOST/$name --output ${destFolder}/${name}__mapping.json --type mapping
  done
}

#
# Import the arranger config indexes dumped with es_export 
#
function es_import() {
  local sourceFolder
  local indexList

  sourceFolder="$1"
  #indexList="$(es_indices 2> /dev/null | grep arranger- | awk '{ print $3 }')"
  indexList=$(ls -1 $sourceFolder | sed 's/__.*json$//' | sort -u)
  for name in $indexList; do
    echo $name
    npx elasticdump --output http://$ESHOST/$name --input $sourceFolder/${name}__data.json --type data
    npx elasticdump --output http://$ESHOST/$name --input $sourceFolder/${name}__mapping.json --type mapping
  done
}

#
# Get the mapping of a given index
#
function es_mapping() {
  local indexName
  indexName=$1
  curl -X GET $ESHOST/_mapping/${indexName}?pretty=true
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

curl  -X POST https://reuben.planx-pla.net/api/v0/flat-search/search/graphql -H 'Content-Type: application/json' -d'
{
"query":"{ subject { __typename } }"
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

fi
