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
  },
  onPageReferenceChanged: function (/*cmp, event, helper*/) {
    $A.get('e.force:refreshView').fire();
  }
});