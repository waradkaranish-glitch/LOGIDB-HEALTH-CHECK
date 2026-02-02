#!/bin/bash

# =========================================================
# LogiDB Health Check
# Email sent if ANY threshold is breached
# =========================================================

# -------- CONFIG --------
H2_JAR="/qond/apps/mfgpro/servers/logi-platform-services/default/platform/connection/drivers/h2-1.4.197.jar"

DB_URL="jdbc:h2:tcp://sfr0bc9xdb01:19193/LogiDB"
DB_USER="sa"
DB_PASS='zy*mur$gy22'

TOKEN_THRESHOLD=600

DB_FILE="/qond/apps/mfgpro/servers/logi-platform-services/default/platform/db/LogiDB.mv.db"
FILE_SIZE_THRESHOLD=$((30 * 1024 * 1024))   # 100 MB

EMAIL_TO="a9w@qad.com"
EMAIL_SUBJECT="DEVL-ALERT: LogiDB Health Threshold Breached:Sage Automotive Interiors "
# ------------------------

ALERT_MSG=""

# -------- CHECK 1: refreshToken count --------
COUNT=$(
java -cp "$H2_JAR" org.h2.tools.Shell \
  -url "$DB_URL" \
  -user "$DB_USER" \
  -password "$DB_PASS" \
  -sql "select count(*) from PLATFORMOBJ where NAMESPACE='system.refreshToken';" \
  | awk '/^[0-9]+$/ {print $1}'
)

if [[ "$COUNT" =~ ^[0-9]+$ ]] && [ "$COUNT" -gt "$TOKEN_THRESHOLD" ]; then
  ALERT_MSG+="[DB ROW COUNT ALERT]\n"
  ALERT_MSG+="Namespace  : system.refreshToken\n"
  ALERT_MSG+="Count      : $COUNT\n"
  ALERT_MSG+="Threshold  : $TOKEN_THRESHOLD\n\n"
fi

# -------- CHECK 2: DB file size --------
if [ -f "$DB_FILE" ]; then
  FILE_SIZE_BYTES=$(stat -c %s "$DB_FILE")
  FILE_SIZE_HR=$(ls -lh "$DB_FILE" | awk '{print $5}')

  if [ "$FILE_SIZE_BYTES" -gt "$FILE_SIZE_THRESHOLD" ]; then
    ALERT_MSG+="[DB FILE SIZE ALERT]\n"
    ALERT_MSG+="File       : $DB_FILE\n"
    ALERT_MSG+="Size       : $FILE_SIZE_HR\n"
    ALERT_MSG+="Threshold  : 100 MB\n\n"
  fi
fi

# -------- SEND EMAIL (ANY condition) --------
if [[ -n "$(echo "$ALERT_MSG" | tr -d '\n ')" ]]; then
  {
    echo "LogiDB Health Alert"
    echo
    echo "This alert indicates abnormal growth detected in the LogiDB database,"
    echo "which may impact WebUI Application performance and couse WebUI down situation."
    echo
    echo "Triggered Conditions"
    echo "-------------------"
    echo -e "$ALERT_MSG"
    echo
    echo "Recommended Action"
    echo "------------------"
    echo "The LogiDB refresh tokens or database size have exceeded defined thresholds"
    echo "and should be cleaned up as per the QAD Knowledge Base article below."
    echo
    echo "KB Article"
    echo "----------"
    echo "https://team.qad.com/x/uYAUF"
    echo
    echo "System Information"
    echo "------------------"
    echo "Host       : $(hostname)"
    echo "Time       : $(date)"
    echo "The above alert is sent as the Logi DB refresh Tokens or DB size has grown and need to cleared by following the KB Article below"
    echo "https://team.qad.com/x/uYAUF"
  } | mail -s "$EMAIL_SUBJECT" "$EMAIL_TO"
fi
exit 0

