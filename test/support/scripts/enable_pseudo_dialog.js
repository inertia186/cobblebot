window.original_alert_function = window.alert;
window.original_confirm_function = window.confirm;
window.pseudoDialog = window.pseudoDialog || {alert:[], confirm:[]};
window.alert = function(msg) { window.pseudoDialog.alert.push(msg);};
window.confirm = function(msg) { window.pseudoDialog.confirm.push(msg);};
