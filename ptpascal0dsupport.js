_ = {
    symbolStack : [],
    counter: 0,
    clearStack: function () {_.symbolStack = []; counter = 0; return "";},
    pushNewSymbol : function () {_symbolStack.push ("v" + _.counter); return "";},
    symbol : function () { return _.symbolStack [_.symbolStack.len () - 1];},
    popSymbol: function () { _.symbolStack.pop (); return ""; }
}
,
