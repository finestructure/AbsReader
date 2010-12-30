#import "../tuneup/tuneup.js"

test("Refresh button", function(target, app) {
  mainWindow = app.mainWindow();
  navBar = mainWindow.navigationBar();
  assertEquals("AbsReader", navBar.name());
  refreshButton = navBar.leftButton();
  refreshButton.tap()
  assertEquals("AbsReader", navBar.name());
});
