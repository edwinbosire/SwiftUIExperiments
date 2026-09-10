function applyHighlight(range) {
	// Create a highlight span
	// var highlightSpan = document.createElement('span');
	// highlightSpan.className = 'highlighted-text';
	// highlightSpan.style.backgroundColor = 'yellow';
	// highlightSpan.style.color = 'black';

	const highlightId = generateUUID();
	var highlightSpan = createHighlightSpan('yellow', highlightId)
	//highlightSpan.appendChild(range.extractContents())
	//range.insertNode(highlightSpan)
	// Set the range contents as the span content
	// const newRange = document.createRange();
	// newRange.selectNode(range.startContainer)
	// newRange.surroundContents(highlightSpan);

	range.surroundContents(highlightSpan);

	// Return highlight info
	return {
		id: Date.now().toString(),
		text: highlightSpan.textContent,
		xpath: getElementXPath(highlightSpan),
		startOffset: range.startOffset,
		endOffset: highlightSpan.textContent.length
	};
}

// Create a span with highlight styling
function createHighlightSpan(color, id) {
	const span = document.createElement('span');
	span.className = 'highlighted-text highlight-' + color;
	span.style.backgroundColor = 'yellow';
	span.setAttribute('data-highlight-id', id);
	return span;
}

// Generate a unique ID for each highlight
function generateUUID() {
	return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
		let r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
		return v.toString(16);
	});
}

function createHighlightFromSelection() {
	var selection = window.getSelection();
	var range
	if (selection.rangeCount && selection.getRangeAt) {
		var range = selection.getRangeAt(0);
		// var safeRanges = getSafeRanges(range);
		// for (var i = 0; i < safeRanges.length; i++) {
		// 	applyHighlight(safeRanges[i]);
		// }
		// } else if (document.selection && document.selection.createRange) {
		// 	range = document.selection.createRange();
		// }

		if (range.collapsed) {
			return;
		}

		if (range.toString().trim().length > 0) {
			// Apply highlight and get info
			var highlightInfo = applyHighlight(range);


			// Clear selection
			selection.removeAllRanges();

			// Send back to Swift
			window.webkit.messageHandlers.highlightHandler.postMessage({
				action: 'addHighlight',
				highlight: highlightInfo
			});
		}
		return highlightInfo;
	}
	return null;
}

function applyStoredHighlights(highlights) {
	highlights.forEach(highlight => {
		try {
			// Get the element using XPath
			// var result = document.evaluate(highlight.xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
			// var element = result.singleNodeValue;
			var element = getElementByXPath(highlight.xpath);
			if (element) {
				// We already have a highlighted span, just need to ensure it has the right class and style
				element.className = 'highlighted-text';
				element.style.backgroundColor = 'yellow';
				element.style.color = 'black';
			}
		} catch (e) {

			if (window.webkit) {
				window.webkit.messageHandlers.errorHandler.postMessage("Error applying highlight:", e);
			} else {
				console.log("Error applying highlights Error:", e);
			}
		}
	});
}

// Get an XPath to an element
function getElementXPath(element) {
	const paths = [];
	while (element && element.nodeType === Node.ELEMENT_NODE) {
		let index = 0;
		let sibling = element.previousSibling;
		while (sibling) {
			if (sibling.nodeType === Node.ELEMENT_NODE && sibling.nodeName === element.nodeName) {
				index++;
			}
			sibling = sibling.previousSibling;
		}
		const tagName = element.nodeName.toLowerCase();
		const pathIndex = index ? `[${index + 1}]` : '';
		paths.unshift(`${tagName}${pathIndex}`);
		element = element.parentNode;
	}
	return paths.length ? `/${paths.join('/')}` : null;
}
// Another popup to show all the highlighted text on the present webpage
// Get the XPath of the element
function getElementByXPath(xpath) {
	return document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
}

// Handle errors
window.onerror = (msg, url, line, column, error) => {
	const message = {
		message: msg,
		url: url,
		line: line,
		column: column,
		error: JSON.stringify(error)
	}

	if (window.webkit) {
		window.webkit.messageHandlers.errorHandler.postMessage(message);
	} else {
		console.log("Console Error:", message);
	}

	return true;
};

document.addEventListener('touchstart', function (e) {
	// 	// This prevents the native selection menu from appearing
	// 	//document.documentElement.style.userSelect = 'none';
	document.documentElement.style.webkitTouchCallout = 'none';

}, false);

document.addEventListener('touchend', function (e) {
	// Re-enable text selection after the touch ends
	//document.documentElement.style.userSelect = 'text';
	document.documentElement.style.webkitTouchCallout = 'none';
	//e.preventDefault();
	// createHighlightFromSelection();
}, false);
document.addEventListener('touchmove', function (e) {
	// createHighlightFromSelection();
}, false);
document.onselectionchange = createHighlightFromSelection;
// Setup document click handler to create highlights
//document.addEventListener('mouseup', function(e) {
//	createHighlightFromSelection();
//});
//document.onmouseup = createHighlightFromSelection;
//document.onkeyup = createHighlightFromSelection;
//document.oncontextmenu = changeColor;
//document.onkeyup = changeColor;

// addEventListener("contextmenu", (event) => {
// 	event.preventDefault();
// 	window.webkit.messageHandlers.errorHandler.postMessage({ message: "contextMenu" });
// });
