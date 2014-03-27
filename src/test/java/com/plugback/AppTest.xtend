package com.plugback

import javax.script.ScriptEngineManager

class AppTest {
	def static void main(String[] args) {
		val engineManager = new ScriptEngineManager
    	val engine = engineManager.getEngineByName("nashorn")
    	engine.eval('''
			var stack = new java.util.LinkedList();
			[1, 2, 3, 4].forEach(function(item) {
			  stack.push(item);
			});
			
			print(stack);
			print(stack.getClass()); 
    	''')
	}
	
}