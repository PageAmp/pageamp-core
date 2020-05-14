/*
 * Copyright (c) 2018-2020 Ubimate Technologies Ltd and PageAmp contributors.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package pageamp.core;

import pageamp.util.PropertyTool.Props;
import pageamp.react.*;
import pageamp.util.BaseNode;
import pageamp.web.DomTools;
using pageamp.web.DomTools;

class Node extends BaseNode {
	public var nodeParent(get,null): Node;
	public inline function get_nodeParent(): Node return untyped baseParent;
	public var nodeChildren(get,null): Array<Node>;
	public inline function get_nodeChildren(): Array<Node> return cast baseChildren;
	public var id: Int;
	public var page(get,null): Page;
	public inline function get_page(): Page return untyped baseRoot;

	function new(parent:Node, ?plug:String, ?index:Int, ?cb:Dynamic->Void) {
		super(parent, plug, index, cb);
		var key = Type.getClassName(Type.getClass(this));
		if (!page.initializations.exists(key)) {
			page.initializations.add(key);
			staticInit();
		}
	}

	public function set(key:String, val:Dynamic, push=true): Value {
		return null;
	}

	public function get(key:String, pull=true): Dynamic {
		return null;
	}

	public inline function refresh() {
		scope != null ? scope.refresh() : null;
	}

#if test
	public function toString() {
		var name = Type.getClassName(Type.getClass(this)).split('.').pop();
		var content = '';
		var plug = 'default';
		var scope = 'n';
		var domNode = getDomNode();
		if (domNode.domIsElement()) {
			content = DomTools.domTagName(untyped domNode);
			plug = cast(this, Element).getProp(Element.PLUG_PROP, 'default');
			this.scope != null ? scope = 'y' : null;
		} else if (domNode.domIsTextNode()) {
			content = cast(domNode, DomTextNode).domGetText();
		}
		return '$name:${id}:$plug:$scope:$content';
	}

	public function dump() {
		var sb = new StringBuf();
		var f = null;
		f = function(n:Node, level:Int) {
			for (i in 0...level) sb.add('\t');
			sb.add(n.toString() + '\n');
			for (c in n.baseChildren) {
				f(untyped c, level + 1);
			}
		}
		f(this, 0);
		return sb.toString();
	}
#end

	// =========================================================================
	// abstract methods
	// =========================================================================

	public function staticInit() {}
	public function getDomNode(): DomNode return null;
	public function cloneTo(parent:Node, index:Int, nesting=0): Node return null;

	// =========================================================================
	// private
	// =========================================================================

	override function init() {
		baseParent == null ? makeScope() : null;
		id = page.nextId();
	}

	function isDynamicValue(k:String, v:Dynamic) {
		return v != null
		&& Std.is(v, String)
		&& !Value.isConstantExpression(untyped v);
	}

	// =========================================================================
	// react
	// =========================================================================
	public var scope: ValueScope;

	public function getScope(): ValueScope {
		var ret:ValueScope = scope;
		if (ret == null && baseParent != null) {
			ret = nodeParent.getScope();
		}
		return ret;
	}

	public function makeScope(?name:String) {
		var pn = baseParent;
		var ps:ValueScope = null;
		while (pn != null) {
			if (Std.is(pn, Element)) {
				var pe:Element = untyped pn;
				if (pe.scope != null) {
					ps = pe.scope;
					break;
				}
			}
			pn = pn.baseParent;
		}
		if (ps == null) {
			scope = new ValueContext(this).main;
		} else {
			var ctx = ps.context;
			scope = new ValueScope(ctx, ps, ctx.newScopeUid(), name);
			scope.set('parent', ps).unlink();
			scope.set('getIndex', getIndex).unlink();
			scope.set('allByName', allByName).unlink();
			scope.set('allByValue', allByValue).unlink();
		}
		name != null ? scope.set('name', name).unlink() : null;
		scope.newValueDelegate = newValueDelegate;
		scope.owner = this;
	}

	function allByName(name:String, obj:Props, cb:ValueScope->Props->Void) {
//		for (child in nodeChildren) {
//			if (child.scope != null && child.scope.name == name) {
//				cb(child.scope, obj);
//			}
//			child.allByName(name, obj, cb);
//		}
		if (scope != null) {
			for (child in scope.children) {
				var v:Value = child.values.get('name');
				if (v != null && v.value == name) {
					cb(child, obj);
				}
				child.owner.allByValue(name, obj, cb);
			}
		}
		return obj;
	}

	function allByValue(name:String, obj:Props, cb:ValueScope->Props->Void) {
//		for (child in nodeChildren) {
//			if (child.scope != null && child.scope.exists(name)) {
//				cb(child.scope, obj);
//			}
//			child.allByName(name, obj, cb);
//		}
		if (scope != null) {
			for (child in scope.children) {
				if (child.exists(name)) {
					cb(child, obj);
				}
				child.owner.allByValue(name, obj, cb);
			}
		}
		return obj;
	}

	function newValueDelegate(v:Value) {}

}