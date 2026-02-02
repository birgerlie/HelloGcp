#!/bin/bash
#
# GCP Setup Script for Workspace Business Agent
#
# This script automates:
#   - Creating a GCP project
#   - Enabling Calendar and Gmail APIs
#   - Creating a service account
#   - Enabling domain-wide delegation
#   - Downloading the credentials JSON
#
# Prerequisites:
#   - gcloud CLI installed (https://cloud.google.com/sdk/docs/install)
#   - Authenticated with: gcloud auth login
#   - Billing account (for enabling APIs)
#
# Usage:
#   ./scripts/setup-gcp.sh [project-id]
#
# Example:
#   ./scripts/setup-gcp.sh my-workspace-agent
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_PROJECT_ID="workspace-agent-$(date +%s)"
PROJECT_ID="${1:-$DEFAULT_PROJECT_ID}"
SERVICE_ACCOUNT_NAME="business-agent-sa"
SERVICE_ACCOUNT_DISPLAY_NAME="Business Agent Service Account"
CREDENTIALS_FILE="credentials.json"

# Scopes for domain-wide delegation
SCOPES="https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/gmail.readonly"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  GCP Setup for Workspace Business Agent${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed.${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
    echo -e "${RED}Error: Not authenticated with gcloud.${NC}"
    echo "Run: gcloud auth login"
    exit 1
fi

CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
echo -e "Authenticated as: ${GREEN}${CURRENT_ACCOUNT}${NC}"
echo ""

# Step 1: Create or select project
echo -e "${YELLOW}Step 1: Setting up GCP project...${NC}"

if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    echo -e "Project ${GREEN}${PROJECT_ID}${NC} already exists. Using it."
else
    echo "Creating project: $PROJECT_ID"
    gcloud projects create "$PROJECT_ID" --name="Workspace Business Agent"
    echo -e "${GREEN}Project created.${NC}"
fi

# Set the project as active
gcloud config set project "$PROJECT_ID"
echo ""

# Step 2: Link billing (may fail if no billing account)
echo -e "${YELLOW}Step 2: Checking billing...${NC}"
BILLING_ACCOUNT=$(gcloud billing accounts list --filter=open=true --format="value(name)" | head -n1)

if [ -n "$BILLING_ACCOUNT" ]; then
    if ! gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null | grep -q "True"; then
        echo "Linking billing account..."
        gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT" || {
            echo -e "${YELLOW}Warning: Could not link billing. You may need to do this manually.${NC}"
        }
    else
        echo "Billing already enabled."
    fi
else
    echo -e "${YELLOW}Warning: No billing account found. APIs may not work without billing.${NC}"
fi
echo ""

# Step 3: Enable APIs
echo -e "${YELLOW}Step 3: Enabling APIs...${NC}"

APIS=(
    "calendar-json.googleapis.com"
    "gmail.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "Enabling $api..."
    gcloud services enable "$api" --project="$PROJECT_ID"
done
echo -e "${GREEN}APIs enabled.${NC}"
echo ""

# Step 4: Create service account
echo -e "${YELLOW}Step 4: Creating service account...${NC}"

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &> /dev/null; then
    echo -e "Service account ${GREEN}${SERVICE_ACCOUNT_EMAIL}${NC} already exists."
else
    gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
        --display-name="$SERVICE_ACCOUNT_DISPLAY_NAME" \
        --description="Service account for Workspace Business Agent with domain-wide delegation"
    echo -e "${GREEN}Service account created.${NC}"
fi
echo ""

# Step 5: Enable domain-wide delegation
echo -e "${YELLOW}Step 5: Enabling domain-wide delegation...${NC}"

# Get the unique ID (client ID) of the service account
CLIENT_ID=$(gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --format="value(uniqueId)")

echo "Enabling domain-wide delegation for the service account..."
# Note: This enables DWD on the service account side, but admin must still authorize in Workspace
gcloud iam service-accounts update "$SERVICE_ACCOUNT_EMAIL" \
    --enable-domain-wide-delegation 2>/dev/null || {
    echo -e "${YELLOW}Note: Domain-wide delegation flag may already be set or requires manual enable in GCP Console.${NC}"
}
echo ""

# Step 6: Create and download key
echo -e "${YELLOW}Step 6: Creating service account key...${NC}"

if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${YELLOW}Warning: $CREDENTIALS_FILE already exists.${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing credentials file."
    else
        rm "$CREDENTIALS_FILE"
        gcloud iam service-accounts keys create "$CREDENTIALS_FILE" \
            --iam-account="$SERVICE_ACCOUNT_EMAIL"
        echo -e "${GREEN}New credentials saved to $CREDENTIALS_FILE${NC}"
    fi
else
    gcloud iam service-accounts keys create "$CREDENTIALS_FILE" \
        --iam-account="$SERVICE_ACCOUNT_EMAIL"
    echo -e "${GREEN}Credentials saved to $CREDENTIALS_FILE${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  GCP Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Project ID:        ${GREEN}${PROJECT_ID}${NC}"
echo -e "Service Account:   ${GREEN}${SERVICE_ACCOUNT_EMAIL}${NC}"
echo -e "Client ID:         ${GREEN}${CLIENT_ID}${NC}"
echo -e "Credentials File:  ${GREEN}${CREDENTIALS_FILE}${NC}"
echo ""

# Save info to a file for reference
cat > .gcp-setup-info << EOF
# GCP Setup Information
# Generated: $(date)

PROJECT_ID=${PROJECT_ID}
SERVICE_ACCOUNT_EMAIL=${SERVICE_ACCOUNT_EMAIL}
CLIENT_ID=${CLIENT_ID}
CREDENTIALS_FILE=${CREDENTIALS_FILE}
EOF

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}  MANUAL STEP REQUIRED${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "You must now configure domain-wide delegation in the"
echo "Google Workspace Admin Console:"
echo ""
echo "1. Go to: https://admin.google.com"
echo "2. Navigate to: Security → API controls → Domain wide delegation"
echo "3. Click 'Add new' and enter:"
echo ""
echo -e "   Client ID: ${GREEN}${CLIENT_ID}${NC}"
echo ""
echo "   OAuth scopes (copy this entire line):"
echo -e "   ${GREEN}${SCOPES}${NC}"
echo ""
echo "4. Click 'Authorize'"
echo ""
echo -e "${BLUE}========================================${NC}"
echo ""
echo "After completing the manual step, create your .env file:"
echo ""
echo "  echo 'WORKSPACE_DOMAIN=yourdomain.com' > .env"
echo ""
echo "Then test with:"
echo ""
echo "  python -m venv venv && source venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  python server.py"
echo ""
