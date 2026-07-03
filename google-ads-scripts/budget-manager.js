/**
 * Google Ads Daily Budget Management Script
 * 
 * Automatically pauses ad groups in labeled campaigns when total account
 * spend exceeds a configurable daily budget threshold, and re-enables
 * them at a specified hour the next day.
 * 
 * Features:
 * - Label-based campaign targeting (only affects campaigns with your chosen label)
 * - Tracking label system (never touches manually paused ad groups)
 * - Configurable re-enable hour (default: 6 AM)
 * - Full logging for audit trail
 * 
 * Setup:
 * 1. Apply the label "gaa" (or your custom label) to campaigns you want managed
 * 2. Set BUDGET_THRESHOLD to your daily cap
 * 3. Set REENABLE_HOUR to when you want ad groups turned back on
 * 4. Schedule the script to run hourly in Google Ads
 * 
 * @author John Williams (@itallstartedwithaidea)
 * @version 1.0.0
 * @license MIT
 * @see https://github.com/itallstartedwithaidea/google-ads-budget-management-script
 */

// ============================================================
// CONFIGURATION — Edit these values to match your account
// ============================================================

var CONFIG = {
  BUDGET_THRESHOLD: 9.50,       // Daily spend cap in dollars
  CAMPAIGN_LABEL: "gaa",        // Label applied to campaigns you want managed
  PAUSED_LABEL: "gaa_paused",   // Tracking label (auto-created by script)
  REENABLE_HOUR: 6              // Hour (0-23) to re-enable paused ad groups
};

// ============================================================
// MAIN FUNCTION
// ============================================================

function main() {
  ensureLabelExists(CONFIG.PAUSED_LABEL);

  var now = new Date();
  var accountTimezone = AdsApp.currentAccount().getTimeZone();
  var currentHour = parseInt(Utilities.formatDate(now, accountTimezone, "H"), 10);

  // Get today's total account spend
  var report = AdsApp.report(
    "SELECT Cost FROM ACCOUNT_PERFORMANCE_REPORT DURING TODAY"
  );

  var rows = report.rows();
  var totalCost = 0;
  while (rows.hasNext()) {
    var row = rows.next();
    totalCost = parseFloat(row["Cost"]);
  }

  Logger.log("Today's spend: $" + totalCost.toFixed(2) + " | Hour: " + currentHour);

  if (totalCost >= CONFIG.BUDGET_THRESHOLD) {
    pauseAdGroups(CONFIG.CAMPAIGN_LABEL, CONFIG.PAUSED_LABEL);
  } else if (currentHour >= CONFIG.REENABLE_HOUR) {
    reEnableAdGroups(CONFIG.CAMPAIGN_LABEL, CONFIG.PAUSED_LABEL);
  } else {
    Logger.log("Spend is under threshold but waiting until " + CONFIG.REENABLE_HOUR + ":00 to re-enable.");
  }
}

// ============================================================
// PAUSE LOGIC
// ============================================================

function pauseAdGroups(campaignLabel, pausedLabel) {
  Logger.log("Spend exceeds threshold. Pausing ad groups...");

  var campaignIterator = AdsApp.campaigns()
    .withCondition("LabelNames CONTAINS_ANY ['" + campaignLabel + "']")
    .withCondition("Status = ENABLED")
    .get();

  var pausedCount = 0;
  while (campaignIterator.hasNext()) {
    var campaign = campaignIterator.next();
    var adGroupIterator = campaign.adGroups()
      .withCondition("Status = ENABLED")
      .get();

    while (adGroupIterator.hasNext()) {
      var adGroup = adGroupIterator.next();
      adGroup.pause();
      adGroup.applyLabel(pausedLabel);
      pausedCount++;
      Logger.log("Paused: " + campaign.getName() + " > " + adGroup.getName());
    }
  }

  Logger.log("Total ad groups paused: " + pausedCount);
}

// ============================================================
// RE-ENABLE LOGIC
// ============================================================

function reEnableAdGroups(campaignLabel, pausedLabel) {
  Logger.log("Re-enabling script-paused ad groups...");

  var campaignIterator = AdsApp.campaigns()
    .withCondition("LabelNames CONTAINS_ANY ['" + campaignLabel + "']")
    .get();

  var enabledCount = 0;
  while (campaignIterator.hasNext()) {
    var campaign = campaignIterator.next();
    var adGroupIterator = campaign.adGroups()
      .withCondition("Status = PAUSED")
      .withCondition("LabelNames CONTAINS_ANY ['" + pausedLabel + "']")
      .get();

    while (adGroupIterator.hasNext()) {
      var adGroup = adGroupIterator.next();
      adGroup.enable();
      adGroup.removeLabel(pausedLabel);
      enabledCount++;
      Logger.log("Re-enabled: " + campaign.getName() + " > " + adGroup.getName());
    }
  }

  Logger.log("Total ad groups re-enabled: " + enabledCount);
}

// ============================================================
// UTILITY FUNCTIONS
// ============================================================

function ensureLabelExists(labelName) {
  var labelIterator = AdsApp.labels()
    .withCondition("Name = '" + labelName + "'")
    .get();

  if (!labelIterator.hasNext()) {
    AdsApp.createLabel(labelName, "Auto-created by budget script", "#FF0000");
    Logger.log("Created label: " + labelName);
  }
}
