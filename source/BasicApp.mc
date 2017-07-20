using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.WatchUi as Ui;

class BasicApp extends App.AppBase {


    function initialize() {
      App.AppBase.initialize();
    }

    // triggered when a user updates the settings in GCM
    function onSettingsChanged() {
      Ui.requestUpdate();
    }

    //! onStart() is called on application start up
    function onStart(state) {
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {

    // This is Jim's code here to debug the 1hz power budget... commented this out before deploying to a watch
    /*
		if( Toybox.WatchUi.WatchFace has :onPartialUpdate ) {
        	return [ new BasicView(), new PartialDelegate()  ];
        } else {
        	return [ new BasicView() ];
        }
    */

    return [ new BasicView() ];

    }

}
