#!/usr/bin/env bash
# Wrapper that replaces `java -jar plantuml.jar` with Docker-based PlantUML.
# Used by plantuml-previewer.vim via g:plantuml_previewer#java_path.
# The plugin calls: <java_path> -Dflag... -jar <jar> -tpng -pipe < input > output
# This script strips the java-specific flags and passes the rest to Docker.

PLANTUML_IMAGE="${PLANTUML_IMAGE:-plantuml/plantuml}"
PLANTUML_VERSION="${PLANTUML_VERSION:-latest}"

args=()
skip_next=false
for arg in "$@"; do
  if $skip_next; then
    skip_next=false
    continue
  fi
  case "$arg" in
    -D*) continue ;;
    -jar) skip_next=true; continue ;;
    *) args+=("$arg") ;;
  esac
done

exec docker run --rm -i \
  -v "$(pwd):/work" \
  -w /work \
  "$PLANTUML_IMAGE:$PLANTUML_VERSION" \
  "${args[@]}"
