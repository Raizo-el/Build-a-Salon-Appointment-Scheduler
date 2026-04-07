#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Create database if it does not exist (connect to default "postgres" DB first)
if ! psql -X --username=freecodecamp --dbname=salon -c "SELECT 1" &>/dev/null; then
  if ! psql -X --username=freecodecamp --dbname=postgres -c "CREATE DATABASE salon;" &>/dev/null; then
    echo "Could not create database 'salon'. In psql as postgres or freecodecamp run:" >&2
    echo "  CREATE DATABASE salon;" >&2
    exit 1
  fi
fi

# First run: load tables and services if missing
if ! psql -X --username=freecodecamp --dbname=salon -t -c "SELECT 1 FROM services LIMIT 1" &>/dev/null; then
  if [[ -f "$SCRIPT_DIR/schema.sql" ]]; then
    psql --username=freecodecamp --dbname=salon -f "$SCRIPT_DIR/schema.sql" || exit 1
  else
    echo "Database 'salon' has no tables. Add schema.sql next to salon.sh or load salon.sql." >&2
    exit 1
  fi
fi

PSQL="psql -X --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

trim() {
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

DISPLAY_SERVICES() {
  $PSQL "SELECT service_id || ') ' || name FROM services ORDER BY service_id"
}

echo -e "\n~~~~~ MY SALON ~~~~~"

echo -e "\nWelcome to My Salon, how can I help you?\n"

DISPLAY_SERVICES

while true; do
  read SERVICE_ID_SELECTED
  if [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
    SERVICE_AVAILABILITY=$($PSQL "SELECT EXISTS(SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED)")
    SERVICE_AVAILABILITY=$(echo "$SERVICE_AVAILABILITY" | xargs)
    if [[ $SERVICE_AVAILABILITY == "t" ]]; then
      break
    fi
  fi
  echo -e "\nI could not find that service. What would you like today?\n"
  DISPLAY_SERVICES
done

echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'" | trim)

if [[ -z $CUSTOMER_ID ]]; then
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  $PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')" >/dev/null
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'" | trim)
else
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID" | trim)
fi

SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED" | trim)

echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

$PSQL "INSERT INTO appointments(customer_id, service_id, \"time\") VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')" >/dev/null

echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
