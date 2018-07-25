#!/bin/bash

ESHOST="localhost:9200"
curl -iv -X DELETE "${ESHOST}/gen3-dev-subject"

#
# `subject` index for arranger-projects-dev project
#
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
          "project": { "type": "text" },
          "study": { "type": "text" },
          "gender": { "type": "keyword" },
          "race": { "type": "keyword" },
          "ethnicity": { "type": "keyword" },
          "vital_status": { "type": "keyword" },
          "file_type": { "type": "keyword" },
          "file_format": { "type": "keyword" }
        }
      }
    }
}
'

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

function es_indices() {
  curl -X GET "${ESHOST}/_cat/indices?v"
}

function es_export() {
  local destFolder
  local indexList

  destFolder="$1"
  mkdir -p "$destFolder"
  indexList="$(es_indices 2> /dev/null | grep arranger- | awk '{ print $3 }')"
  for name in $indexList; do
    echo $name
    npx elasticdump --input http://$ESHOST/$name --output ${destFolder}/${name}__data.json --type data
    npx elasticdump --input http://$ESHOST/$name --output ${destFolder}/${name}__mapping.json --type mapping
  done
}


function es_import() {
  local destFolder
  local indexList

  destFolder="$1"
  #indexList="$(es_indices 2> /dev/null | grep arranger- | awk '{ print $3 }')"
  indexList="$(ls -1 data | sed 's/__.*json$//' | sort -u)"
  for name in $indexList; do
    echo $name
    npx elasticdump --output http://$ESHOST/$name --input data/${name}__data.json --type data
    npx elasticdump --output http://$ESHOST/$name --input data/${name}__mapping.json --type mapping
  done
}

function es_mapping() {
  local indexName
  indexName=$1
  curl -X GET $ESHOST/_mapping/${indexName}?pretty=true
}

function es_index_records() {
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
  "project": "Proj-${projectIndex}",
  "study": "Study-${projectIndex}${studyIndex}",
  "gender": "${gender}",
  "ethnicity": "${ethnicity}",
  "race": "${race}",
  "vital_status": "${vital}",
  "file_type": "${fileType}",
  "file_format": "${fileFormat}"
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

es_dump gen3-dev-subject
es_index_records 0 100