function stackdir() {
        STACK="${1}"

        echo "/var/data/composefiles/${STACK}"
}

function hasstack() {
        STACK="${1}"
        STACKDIR=$(stackdir "${STACK}")

        if [ -d "${STACKDIR}" ]; then
                return 0;
        else
                return 1;
        fi;
}

function tostack() {
        STACK="${1}"

        if hasstack "${STACK}"; then
                cd "$(stackdir "${STACK}")"
        else
                echo "No such stack: ${STACK}"
        fi;
}

function runstack() {
        STACK="${1}"

        if [ "${STACK}" = "" -o "${STACK}" = "." ]; then
                STACK="$(basename ${PWD})"
                if [ "$(stackdir "${STACK}")" != "${PWD}" ]; then
                        echo "Invalid directory."
                fi;
        fi;

        if hasstack "${STACK}"; then
                docker stack deploy --prune --with-registry-auth --compose-file="$(stackdir "${STACK}")/docker-compose.yml" "${STACK}"
        else
                echo "No such stack: ${STACK}"
        fi;
}

function stopstack() {
        STACK="${1}"

        if [ "${STACK}" = "" -o "${STACK}" = "." ]; then
                STACK="$(basename ${PWD})"
                if [ "$(stackdir "${STACK}")" != "${PWD}" ]; then
                        echo "Invalid directory."
                fi;
        fi;

        docker stack rm "${STACK}"
}

function servicefind() {
        SERVICE="${1}"

        docker service ps --no-trunc --filter "desired-state=running" --format "{{.Node}} {{.Name}}.{{.ID}}" "${SERVICE}"
}

function serviceexec() {
        SERVICE="${1}"
        shift;

        COUNT=$(servicefind "${SERVICE}" | wc -l)
        INFO=""

        if [ "${COUNT}" -eq 0 ]; then
                echo "Service not found."
                return 1;
        else
                echo "Found service."

                NUM="${1}"

                WANTED=""
                if [[ "${NUM}" =~ ^[0-9]+$ ]]; then
                        WANTED="${NUM}"
                        shift;

                        if [ "${1}" = "" ]; then
                                echo "No command provided."
                                return 1;
                        fi;

                        WHAT="${@}"
                else
                        echo "Pick a service:"
                fi;

                I=0
                while read SINFO; do
                        if [ "${WANTED}" != "" ]; then
                                if [ "${WANTED}" = "${I}" ]; then
                                        INFO="${SINFO}"
                                fi;
                        else
                                echo "${I} ${SINFO}"
                        fi;

                        ((I++))
                done <<< "$(servicefind "${SERVICE}")"

                if [ "${WANTED}" = "" ]; then
                        return 1;
                fi;
        fi;

        if [ "${INFO}" != "" ]; then
                HOST="$(echo "${INFO}" | awk '{print $1}')"
                CONTAINER="$(echo "${INFO}" | awk '{print $2}')"

                echo ""
                echo "----------"
                echo "Using container '${CONTAINER}' on '${HOST}'"
                echo "Running: ${WHAT}"
                echo "----------"
                echo ""

                ssh ${HOST} -t docker exec -it "${CONTAINER}" "${WHAT}"
        else
                echo "No valid service found."
        fi;
}


function servicelogsall() {
        docker service logs "${@}"
}

function servicelogs() {
        SERVICE="${1}"
        shift;

        COUNT=$(servicefind "${SERVICE}" | wc -l)
        INFO=""

        if [ "${COUNT}" -eq 0 ]; then
                echo "Service not found."
                return 1;
        else
                echo "Found service."

                NUM="${1}"

                WANTED=""
                if [[ "${NUM}" =~ ^[0-9]+$ ]]; then
                        WANTED="${NUM}"
                        shift;
                else
                        echo "Pick a service:"
                fi;

                I=0
                while read SINFO; do
                        if [ "${WANTED}" != "" ]; then
                                if [ "${WANTED}" = "${I}" ]; then
                                        INFO="${SINFO}"
                                fi;
                        else
                                echo "${I} ${SINFO}"
                        fi;

                        ((I++))
                done <<< "$(servicefind "${SERVICE}")"

                if [ "${WANTED}" = "" ]; then
                        return 1;
                fi;
        fi;

        if [ "${INFO}" != "" ]; then
                HOST="$(echo "${INFO}" | awk '{print $1}')"
                CONTAINER="$(echo "${INFO}" | awk '{print $2}')"

                echo ""
                echo "----------"
                echo "Using container '${CONTAINER}' on '${HOST}'"
                echo "----------"
                echo ""

                ssh ${HOST} -t docker logs "${@}" "${CONTAINER}"
        else
                echo "No valid service found."
        fi;
}


function drain() {
        NODE=`hostname`

        echo "Draining ${NODE}";

        echo "Draining node..."
        docker node update --availability drain "${NODE}"
        sleep 2;

        echo "Pause Ceph..."
        ssh ${NODE} -t ceph osd set noout

        echo "Failing ceph-mds to ensure failover."
        ssh ${NODE} -t ceph mds fail \`hostname -s\`

        echo "Done."
}

function undrain() {
        NODE=`hostname`

        echo "Undraining ${NODE}";
        docker node update --availability Active "${NODE}"
        sleep 2;

        DRAINING=`docker node ls --format {{.Availability}} | grep -i drain | wc -l`
        if [ "${DRAINING}" = "0" ]; then
                echo "Resume Ceph..."
                ssh ${NODE} -t ceph osd unset noout
                sleep 2;
        fi;
}
