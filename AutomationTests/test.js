#import "../tuneup/tuneup.js"

// mainWindow.logElementTree();
// UIATarget.localTarget().captureScreenWithName("refresh_all");

UIATarget.onAlert = function onAlert(alert) {
  var title = alert.name();
  UIALogger.logWarning("Alert with title '" + title + "' encountered!");

  if (title == "Error fetching feed") {
    alert.buttons()["Continue"].tap();
    return true; // bypass default handler
  }
  return false; // use default handler
}

test("Add feed", function(target, app) {
  mainWindow = app.mainWindow();
  navBar = mainWindow.navigationBar();
  addButton = navBar.buttons()[1];
  addButton.tap();
  mainWindow.textFields()["title"].setValue("Test Feed")
  mainWindow.textFields()["url"].setValue("http://test.com")
  cancelButton = navBar.buttons()[0];
  cancelButton.tap();
});


/*
test("Refresh all", function(target, app) {
  mainWindow = app.mainWindow();
  navBar = mainWindow.navigationBar();
  assertEquals("AbsReader", navBar.name());
  toolbar = mainWindow.toolbar();
  refreshButton = toolbar.buttons()[1];
  refreshButton.tap()
});
*/


