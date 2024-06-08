bob@caleston-lp10:~$ cat /usr/local/bin/rocket
#!/bin/bash

if [ -z ${1} ]
then
  echo "Please provide a functionality. One of add | start-power | internal-power | start-sequence | start-engine | lift-off | status"
  exit 1
fi

if [ -z ${2} ]
then
  echo "Please input a mission name in the form rocket <mission name>"
  echo "eg: rocket add lunar-mission"
  exit 1
fi

function_name=$1
mission_name=$2


# Optional environment variables
# COUNT_DOWN - seconds for countdown before launch - Default 10
# STATUS_DELAY - seconds to wait before setting status - Default 1
# POST_LIFT_OFF_DELAY - Delay before setting a success state post lift off - Default 5
# MUST_FAIL - "true" Launch fails
# FAILURE_REASON - A reason for a faulure


[[ -z "${STATUS_DELAY}" ]] && status_delay=1 || status_delay=${STATUS_DELAY}
[[ -z "${COUNT_DOWN}" ]] && count_down_from=10 || count_down_from=${COUNT_DOWN}
[[ -z "${POST_LIFT_OFF_DELAY}" ]] && post_lift_off_sequence_delay=5 || post_lift_off_sequence_delay=${POST_LIFT_OFF_DELAY}

failReasons=("extreme_temparature" "upper_stage_anomaly" "booster_pump_failure" "liquid_boosters_failure")

print-color() {

  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color

  case $1 in
  red)
    COLOR=$RED
    ;;
  green)
    COLOR=$GREEN
    ;;
  esac

  printf "${COLOR}$2${NC}"
}

check-if-mission-exists (){
  [ ! -d "$(pwd)/$mission_name" ] && echo "Mission directory does not exist." && exit 1
}

set-status (){
    check-if-mission-exists
    sleep ${status_delay}
    echo "$1" > "$(pwd)/$mission_name/status"
    print-color green "Done!\n"
}

get-status (){
    check-if-mission-exists
    cat "$(pwd)/$mission_name/status"
}

set-reason () {
  local reason=$1
  check-if-mission-exists
  echo "$reason" > "$(pwd)/$mission_name/reason"
}

get-reason () {
  check-if-mission-exists
  cat "$(pwd)/$mission_name/reason"
}

rocket-add () {
  printf "\n--------------------------------------------"
  printf "\n          PROJECT %s           " $mission_name
  printf "\n--------------------------------------------"
  printf "\nCreating a new rocket...."
  set-status "created"
}

rocket-start-power () {
  printf "\nStarting power ...."
  set-status "start-power"
}

rocket-internal-power () {
  printf "\nSwitching to internal ...."
  set-status "internal-power"
}

rocket-start-sequence () {
  printf "\nStarting auto sequence ...."
  set-status "start-sequence"
}

rocket-start-engine () {
  printf "\nStarting engine ...."
  set-status "start-engine"
}

rocket-lift-off () {
  printf "\nInitiating lift off ...."
  print-color red "\n        Countdown"
  for i in $(eval echo {$count_down_from..0})
        do
                print-color red "\n          $i"
                sleep ${status_delay}
        done
  print-color green "\n   !!!!Lift off!!!\n"
  set-status "launching"
  cat /usr/local/bin/rocket.vt | pv -qL 300 && clear
  rocket-lift-off-sequence > /dev/null &
  # rocket-lift-off-sequence &
}

rocket-lift-off-sequence () {
  sleep ${post_lift_off_sequence_delay}
  # If must fail environment variable is set fail the launch and set a random reason
  if [ "${MUST_FAIL}" = true ]
  then
      set-status "failed"
      # If failure reason environment variable is set, use that.
      # If not set set a random reason
      if [ -z ${FAILURE_REASON} ]
      then
        rand=$[$RANDOM % ${#failReasons[@]}]
        fail_reason=${failReasons[$rand]}
        echo "Setting reason ${fail_reason}"
        set-reason ${fail_reason}
      else
        set-reason ${FAILURE_REASON}
      fi
  else
      set-status "success"
  fi
}

rocket-status () {
  sleep ${status_delay}
  get-status
}

rocket-debug () {
  get-reason
}

case $function_name in
  add)
    rocket-add
    ;;
  start-power)
    rocket-start-power
    ;;
  internal-power)
    rocket-internal-power
    ;;
  start-sequence)
    rocket-start-sequence
    ;;
  start-engine)
    rocket-start-engine
    ;;
  lift-off)
    rocket-lift-off
    ;;
  status)
    rocket-status
    ;;
  debug)
    rocket-debug
    ;;
  all)
    rocket-add
    rocket-start-power
    rocket-internal-power
    rocket-start-sequence
    rocket-start-engine
    rocket-lift-off
    rocket-status
