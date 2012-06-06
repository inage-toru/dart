#library('jsonp');

#import('dart:html');
#import('dart:json');

interface JSONP default _JSONPImpl {
  JSONP(String uri, [String callbackParamName]);
  void send(Function replyCallback);
}

class _JSONPImpl implements JSONP {
  static Map<String, _JSONPImpl> _instanceMap;
  
  ScriptElement _callback, _request;
  
  String _callbackParamName;
  
  Function _replyCallback;
  
  String _uri;
  
  factory _JSONPImpl(String uri, [String callbackParamName = 'callbackForJsonpApi']) {
    if (_instanceMap == null) _instanceMap = new Map<String, _JSONPImpl>();
    if (!_instanceMap.containsKey(callbackParamName)) {
      _instanceMap[callbackParamName] = new _JSONPImpl._internal(uri, callbackParamName);
    } else {
      _instanceMap[callbackParamName]._uri = uri;
    }
    return _instanceMap[callbackParamName];
  }
  
  _JSONPImpl._internal(this._uri, this._callbackParamName)
      : _callback = new Element.tag('script') {
    window.on.message.add(_dataReceived);
    _appendScriptElementForCallback(document.body);
  }
  
  void send(Function replyCallback) {
    _replyCallback = replyCallback;
    _appendScriptElementForRequest(document.body);
  }
  
  void _appendScriptElementForCallback(Element element) {
    _callback.innerHTML = new StringBuffer()
      .add('function $_callbackParamName(data) {')
      .add('var json = { name: arguments.callee.name, data: data };')
      .add('window.postMessage(JSON.stringify(json), "*");')
      .add('}')
      .toString();
    element.elements.add(_callback);
  }
  
  void _appendScriptElementForRequest(Element element) {
    _request = new Element.tag('script');
    _request.src = '$_uri&callback=$_callbackParamName';
    document.body.elements.add(_request);
  }
  
  void _dataReceived(MessageEvent event) {
    var result = JSON.parse(event.data);
    if (_callbackParamName == result['name']) {
      _replyCallback(result['data']);
      _request.remove();
      _request = null;
    }
  }
}