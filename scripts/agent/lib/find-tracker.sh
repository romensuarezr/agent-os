# find-tracker.sh — Helper compartido para localizar el MVP Tracker en el repositorio
# Expone la función find_tracker() que busca en orden de preferencia de casing y ubicación.

find_tracker() {
  local root="${1:-$(pwd)}"
  if   [[ -f "$root/docs/mvp-tracker.md" ]];  then echo "$root/docs/mvp-tracker.md"
  elif [[ -f "$root/docs/MVP-TRACKER.md" ]];  then echo "$root/docs/MVP-TRACKER.md"
  elif [[ -f "$root/mvp-tracker.md" ]];       then echo "$root/mvp-tracker.md"
  elif [[ -f "$root/MVP-TRACKER.md" ]];       then echo "$root/MVP-TRACKER.md"
  else echo ""; fi
}
