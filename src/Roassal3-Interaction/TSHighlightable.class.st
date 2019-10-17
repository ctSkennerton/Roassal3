"
I a basic interaction to add highlighting events to elements in view.
"
Class {
	#name : #TSHighlightable,
	#superclass : #TSInteraction,
	#instVars : [
		'highlightElements',
		'highlightShape',
		'announcer',
		'attributeKey',
		'copyKey'
	],
	#category : #'Roassal3-Interaction-Core'
}

{ #category : #'instance creation' }
TSHighlightable class >> onElement: element [
	instance ifNil: [ 
		instance := self new.
		instance highlightShape color: Color red.
		 ].
	instance onElement: element.
	^ instance 
]

{ #category : #announce }
TSHighlightable >> announce: anEvent [
	announcer ifNil: [ ^ self ].
	announcer announce: anEvent value
]

{ #category : #announce }
TSHighlightable >> announceHighlight: element source: anElementOrView [
	self announce: [ TSHighlightEvent new
		interaction: self;
		element: element;
		source: anElementOrView ].
]

{ #category : #announce }
TSHighlightable >> announceUnHightlight: element source: anElementOrView [
	self announce: [ TSUnHighlightEvent new
		interaction: self;
		element: element;
		source: anElementOrView ].
]

{ #category : #accessing }
TSHighlightable >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ].
]

{ #category : #accessing }
TSHighlightable >> announcer: anAnnouncer [
	announcer := anAnnouncer
]

{ #category : #'accessing - keys' }
TSHighlightable >> attributeKey [
	^ attributeKey ifNil: [ attributeKey := #highlightElements ].
]

{ #category : #'accessing - keys' }
TSHighlightable >> attributeKey: aSymbol [
	attributeKey := aSymbol.
]

{ #category : #'accessing - keys' }
TSHighlightable >> copyKey [
	^ copyKey ifNil: [ copyKey := #original ].
]

{ #category : #'accessing - keys' }
TSHighlightable >> copyKey: aSymbol [
	copyKey := aSymbol
]

{ #category : #actions }
TSHighlightable >> doHighlight: element [
	| elements |
	self unhighlightRecordedElements: element.
	elements := self highlightElementsFor: element.
	elements do: [ :e | 
		self doHighlightElement: e.
		self announceHighlight: e source: element. ].
	
	element topParent view attributes at: self attributeKey put: elements.
]

{ #category : #'public - hooks' }
TSHighlightable >> doHighlightElement: element [
	self recordIfNecessary: element.
	highlightShape commands ifEmpty: [ ^ self ].
	highlightShape updateElement: element.
]

{ #category : #actions }
TSHighlightable >> doHighlightElements: elements [
	| allHElements |
	elements ifEmpty: [ ^ self ].
	self unhighlightRecordedElements: elements first.
	allHElements := elements flatCollect: [ :e | | helements |
		helements := self highlightElementsFor: e.
		helements do: [ :he | 
			self doHighlightElement: he.
			self announceHighlight: he source: e ].
		helements ].
	
	elements first view attributes at: self attributeKey put: allHElements.
]

{ #category : #actions }
TSHighlightable >> doUnhighlight: anElement [
	self unhighlightRecordedElements: anElement
]

{ #category : #'public - hooks' }
TSHighlightable >> doUnhighlightElement: element [
	| att s originals args |
	att := element attributes.
	(att includesKey: self copyKey) ifFalse: [ ^ self ].
	s := element shape.
	originals := att at: self copyKey.
	args := Array new: 1.
	originals keysAndValuesDo: [ :key :value | 
		args at: 1 put: value.
		s perform: key withArguments: args ].
	att removeKey: self copyKey.
]

{ #category : #accessing }
TSHighlightable >> highlightElements [
	^ highlightElements
]

{ #category : #accessing }
TSHighlightable >> highlightElements: aBlock [
	highlightElements := aBlock
]

{ #category : #'highlight elements' }
TSHighlightable >> highlightElements: aBlock butKeep: aRSHilightable [
	"aBlock recives an element and return a collection of elements"
	self highlightElements: [ :e | 
		| elements |
		elements := aBlock value: e.
		e view attributes
			at: aRSHilightable attributeKey
			ifPresent: [ :helements | 
				
				elements reject: [ :he | helements includes: he ] ]
			ifAbsent: [ elements ] ]
]

{ #category : #'accessing - computed' }
TSHighlightable >> highlightElementsFor: element [
	^ highlightElements rsValue: element
]

{ #category : #accessing }
TSHighlightable >> highlightShape [
	"
	Gives a highlight shape. Useful to change the color of the highlight. 

For example
-=-=-=
v := RSView new.

sb := RSShapeBuilder box
			elementsOn: (1 to: 100).
v addAll: sb.

highlight := RSHighlightable new.
highlight highlightShape color: Color red trans.
sb @ highlight.
RSGridLayout on: sb.
v @ RSControlsView.
v open			
-=-=-=
	"
	^ highlightShape ifNil: [
		self highlightShape: RSShapeBuilder box.
		highlightShape ]
]

{ #category : #accessing }
TSHighlightable >> highlightShape: aShapeBuilder [
	highlightShape := aShapeBuilder.
	highlightShape commands removeAll.
]

{ #category : #initialization }
TSHighlightable >> initialize [
	super initialize.
	self highlightElements: [ :el | Array with: el ].

]

{ #category : #hooks }
TSHighlightable >> onShape: aShape [
	aShape
		when: TSMouseEnter do: [ self doHighlight: aShape. aShape signalUpdate ];
		when: TSMouseLeave do: [ self doUnhighlight: aShape. aShape signalUpdate ]
]

{ #category : #'public - hooks' }
TSHighlightable >> record: element [
	element attributes 
		at: self copyKey 
		put: (self highlightShape currentGetterValues: element)
]

{ #category : #public }
TSHighlightable >> recordElements: elements [
	elements do: [ :e | self record: e ].
]

{ #category : #actions }
TSHighlightable >> recordIfNecessary: element [
	| att |
	att := element attributes.
	(att includesKey: self copyKey) ifTrue: [ ^ self ].
	self record: element.
]

{ #category : #actions }
TSHighlightable >> resetHighlightedElements: anElementOrView [
	| att |
	att := anElementOrView topParent view attributes.
	(att includesKey: self attributeKey) ifFalse: [ ^ self ].
	att removeKey: self attributeKey
]

{ #category : #public }
TSHighlightable >> setupAntAnimation [
	self withEdges.
	self highlightShape
		border: [ TSBorder new width: 2; color: Color red ].
	self when: TSHighlightEvent do: [ :evt | | e |
		(e := evt element) isElement ifTrue: [ 
			| array anime |
			array := #(4).
			e connectedEdges do: [ :ed| ed border 
				color: Color blue; 
				width: 2;
				dashArray: array. ].
			anime := e newAnimation
				repeat;
				from: 0;
				to: -8;
				duration: 1 second;
				onStepDo: [ :t |
					e connectedEdges do: [ :ed |ed border dashOffset: t ].
					e signalUpdate ].
			e topParent view attributes at: #antAnimation put: anime.
		].
	].
	self when: TSUnHighlightEvent do: [ :evt | 
		| att e |
		e := evt element.
		e isElement ifTrue: [ 
			att := evt element topParent view attributes.
			(att at: #antAnimation) stop.
			att removeKey: #antAnimation.
		 ]
	].
]

{ #category : #actions }
TSHighlightable >> unhighlightRecordedElements: anElementOrView [
	
	anElementOrView topParent view attributes at: self attributeKey ifPresent: [ :elements |
		elements do: [ :e | 
			self doUnhighlightElement: e.
			self announceUnHightlight: e source: anElementOrView.
			 ].
		 ].
	self resetHighlightedElements: anElementOrView
]

{ #category : #announcing }
TSHighlightable >> when: event do: aBlock [
	self announcer when: event do: aBlock
]

{ #category : #'highlight elements' }
TSHighlightable >> withEdges [
	self highlightElements: [ :e | e connectedEdges copy add: e; yourself ].
]

{ #category : #'highlight elements' }
TSHighlightable >> withIncomingEdges [
	self highlightElements: [ :e | e incomingEdges copy asOrderedCollection add: e; yourself ].
]

{ #category : #'highlight elements' }
TSHighlightable >> withOutgoingEdges [
	self highlightElements: [ :e | e outgoingEdges copy asOrderedCollection add: e; yourself ].
]