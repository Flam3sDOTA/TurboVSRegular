"use strict";

var NoDashboardButton = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("MenuButtons");
var NoScoreboardButton = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("MenuButtons");
var NoSettingsButton = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("MenuButtons");

NoDashboardButton.FindChildTraverse("DashboardButton").style.visibility = "collapse";
NoScoreboardButton.FindChildTraverse("ToggleScoreboardButton").style.visibility = "collapse";
NoSettingsButton.FindChildTraverse("SettingsRebornButton").style.visibility = "collapse";

GameEvents.Subscribe("show_sell_error", function(event) {
    var panel = $("#SellErrorPanel");
    $("#SellErrorLabel").text = event.message || "Shop Not In Range, Try Touching Grass";
    if (!panel) return;
    panel.style.visibility = "visible";
    panel.style.opacity = "1.0";
    Game.EmitSound("General.InvalidTarget_Invulnerable")
    $.Schedule(2.0, function() {
        panel.style.opacity = "0.0";
        $.Schedule(0.4, function() {
            panel.style.visibility = "collapse";
            panel.style.opacity = "1.0";
        });
    });
});

var aegisTickSchedule = null; 

GameEvents.Subscribe("start_aegis_countdown", function(event) {
    var panel = $("#AegisCountdownPanel");
    var label = $("#AegisCountdownLabel");
    if (!panel || !label) return;

    if (aegisTickSchedule !== null) {
        $.CancelScheduled(aegisTickSchedule);
        aegisTickSchedule = null;
    }

    var remaining = event.duration || 240;
    panel.style.visibility = "visible";

    function hideItemTimers() {
        var hud = $.GetContextPanel().GetParent().GetParent().GetParent();
        var inventory = hud.FindChildTraverse("inventory_list2");
        if (inventory) {
            var slots = inventory.Children();
            for (var i = 0; i < slots.length; i++) {
                var timer = slots[i].FindChildTraverse("ItemTimer");
                if (timer) timer.style.visibility = "collapse";
            }
        }
    }

    function updateLabel() {
        var mins = Math.floor(remaining / 60);
        var secs = remaining % 60;
        label.text = "Aegis: " + mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function tick() {
        remaining -= 1;
        hideItemTimers();
        if (remaining <= 0) {
            panel.style.visibility = "collapse";
            aegisTickSchedule = null;
            return;
        }
        updateLabel();
        aegisTickSchedule = $.Schedule(1.0, tick);
    }

    hideItemTimers();
    updateLabel();
    aegisTickSchedule = $.Schedule(1.0, tick);
});

GameEvents.Subscribe("hide_aegis_countdown", function(event) {
    var panel = $("#AegisCountdownPanel");
    if (panel) panel.style.visibility = "collapse";
    
    if (aegisTickSchedule !== null) {
        $.CancelScheduled(aegisTickSchedule);
        aegisTickSchedule = null;
    }
});

function ToggleSlarkCrawl() {
    var panel = $("#SlarkCrawlPanel");
    if (!panel) return;
    if (panel.style.visibility === "visible") {
        panel.style.visibility = "collapse";
        panel.RemoveClass("crawl_active");
    } else {
        panel.RemoveClass("crawl_active");
        panel.style.visibility = "visible";
        $.Schedule(0.1, function() {
            panel.AddClass("crawl_active");
        });
    }
}

var customBtn1 = $("#CustomButton1");
if (customBtn1) {
    customBtn1.SetPanelEvent("onactivate", ToggleSlarkCrawl);
}