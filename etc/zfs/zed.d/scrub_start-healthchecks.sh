#!/bin/sh
#
# Send notification in response to SCRUB_START or SCRUB_FINISH.
# The notification is sent to healthchecks.io, one when the scrub starts,
# and another one when it finishes (which allows measuring time to scrub).
# In order to configure where the notification should be sent,
# ZED_HEALTHCHECKS_URL variable should carry the URL.
#
# Exit codes:
#   0: notification sent
#   1: notification failed
#   9: internal error

[ -f "${ZED_ZEDLET_DIR}/zed.rc" ] && . "${ZED_ZEDLET_DIR}/zed.rc"
. "${ZED_ZEDLET_DIR}/zed-functions.sh"

[ -n "${ZEVENT_POOL}" ] || exit 9
[ -n "${ZEVENT_SUBCLASS}" ] || exit 9

notification_url="${ZED_HEALTHCHECKS_URL}"
# If you don't want to modify zed.rc, you can hardcode the URL here
if [ -z "$notification_url" ]; then
	notification_url="https://hc-ping.com/191967ab-d690-4798-badb-a4bee75ede53"
fi


# When we start scrubbing, we only need to send the notification
# of when the scrubbing starts, no extra information is needed
if [ "${ZEVENT_SUBCLASS}" = "scrub_start" ]; then

	notification_url="$notification_url/start"

# When we stop scrubbing, we check for how healthy the pool is;
# if any errors are found, the URL is modified to indicate failure
elif [ "${ZEVENT_SUBCLASS}" = "scrub_finish" ]; then

	# Verify that we've got needed tools
	zed_check_cmd "${ZPOOL}" || exit 9

	# If the pool is _not_ healthy (-v for grep means inverse of result, -q reduces it to exit code),
	# then signal failure instead of success by appending "/fail" to the URL
	if "${ZPOOL}" status -x "${ZEVENT_POOL}" | grep -qv "pool '${ZEVENT_POOL}' is healthy"; then
		notification_url="$notification_url/fail"
	fi

	# Gather pool status for finish report
	pool_status="$("${ZPOOL}" status "${ZEVENT_POOL}")"

# If any other event is being executed here,
# make sure to throw the right error message
else
	zed_log_err "unsupported event class \"${ZEVENT_SUBCLASS}\""
	exit 9
fi

# Send the notification out (with pool status as log if available)
if [ -n "$pool_status" ]; then
	curl -fsS --retry 5 --data-raw "$pool_status" "$notification_url"; rv=$?
else
	curl -fsS --retry 5 "$notification_url"; rv=$?
fi

exit "$rv"
