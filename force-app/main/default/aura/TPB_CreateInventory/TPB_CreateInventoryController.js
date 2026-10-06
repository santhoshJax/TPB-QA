({
	init : function(component, event, helper) {
        //find component whose aura:id equals "flowData"
        var flow = component.find("flowData");
        flow.startFlow("TPB_CreateInventory");
	}
})