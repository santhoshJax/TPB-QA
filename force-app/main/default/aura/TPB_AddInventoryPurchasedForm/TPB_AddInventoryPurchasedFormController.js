({
  init: function (cmp) {
    var recordId = cmp.get('v.recordId');
    if (recordId === undefined || recordId == null) {
      var pageRef = cmp.get('v.pageReference');
      var state = pageRef.state; // state holds any query params
      var base64Context = state.inContextOfRef;

      // For some reason, the string starts with "1.", if somebody knows why,
      // this solution could be better generalized.
      if (base64Context.startsWith('1.')) {
        base64Context = base64Context.substring(2);
      }
      var addressableContext = JSON.parse(window.atob(base64Context));
      cmp.set('v.recordId', addressableContext.attributes.recordId);
    }

    recordId = cmp.get('v.recordId');

    if (recordId) {
      // call apex getRecordTypeName(recordId)
      var typeName;
      var action = cmp.get('c.getOrderRecordType');
      action.setParams({ strRecordId: recordId });
      action.setCallback(this, function (response) {
        var resState = response.getState();
        var data;

        if (resState === 'SUCCESS') {
          data = response.getReturnValue();
          // {"data":"Mass_Prebook","result":"OK"}

          if (data.result === 'OK') {
            typeName = data.data;
          }
        }

        if (typeName === 'Mass_Prebook') {
          cmp.set('v.renderMassPrebookOrder', true);
        } else {
          cmp.set('v.renderWholesalerOrder', true);
        }
      });
      $A.enqueueAction(action);
    } else {
      // entry wholesaler order when no recordId
      cmp.set('v.renderWholesalerOrder', true);
    }
  },
  onPageReferenceChanged: function (/*cmp, event, helper*/) {
    $A.get('e.force:refreshView').fire();
  }
});