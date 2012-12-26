## GLOBALS ##

# Object: Default settings
defaultSettings =
	type: 'single'
	chars: 14
	howmany: 1
	security:
		lowercase: true
		uppercase: true
		special: true
		punctuation: true
		readable: false

# Object: Current settings
paGenSettings = defaultSettings

# Object: Window Heights
windowHeights =
	single: '190px'
	multiple: '270px'
	settings: '355px'

## HELPERS ##

# Prototype extend: Shuffle a string
String::shuffle = ->
	a = @split("")
	n = a.length
	i = n - 1

	while i > 0
		j = Math.floor( Math.random() * (i + 1) )
		tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
		--i

	a.join ""

# Function: Extend JS Object
extend = (obj, extObj) ->
	for i of extObj
		obj[i] = extObj[i]
	obj

# Function: Throw Error
throwError = (message) ->
	notification = window.webkitNotifications.createNotification(
		'icon.png',
		window.chrome.i18n.getMessage( 'error' ),
		"#{message}"
	)

	notification.show()

	false

# Function: Show Notification
showNotification = (message) ->
	notification = window.webkitNotifications.createNotification(
		'icon.png',
		window.chrome.i18n.getMessage( 'information' ),
		"#{message}"
	)

	notification.show()

	false

# Function: Apply i18n
applyi18n = () ->
	# HTML
	elements = document.getElementsByClassName('apply-i18n')
	i = 0
	while i < elements.length
		element = elements[i]
		messageId = element.innerHTML
		element.innerHTML = window.chrome.i18n.getMessage messageId
		++i

	# placeholder attribute
	elements = document.getElementsByClassName('apply-i18n-placeholder')
	i = 0
	while i < elements.length
		element = elements[i]
		messageId = element.placeholder
		element.placeholder = window.chrome.i18n.getMessage messageId
		++i

	# title attribute
	elements = document.getElementsByClassName('apply-i18n-title')
	i = 0
	while i < elements.length
		element = elements[i]
		messageId = element.title
		element.title = window.chrome.i18n.getMessage messageId
		++i

	# alt attribute
	elements = document.getElementsByClassName('apply-i18n-alt')
	i = 0
	while i < elements.length
		element = elements[i]
		messageId = element.alt
		element.alt = window.chrome.i18n.getMessage messageId
		++i
	true

# Function: Validate Settings
validateSettings = (settings, notify) ->
	if !settings
		settings = paGenSettings

	if !settings.type || ( settings.type != 'single' && settings.type != 'multiple' )
		if notify
			throwError window.chrome.i18n.getMessage( 'validateType' )
		false

	if !settings.chars || isNaN settings.chars || settings.chars < 1 || settings.chars > 128
		if notify
			throwError window.chrome.i18n.getMessage( 'validateChars' )
		false

	if !settings.howmany || isNaN settings.howmany || settings.howmany < 1 || settings.howmany > 20
		if notify
			throwError window.chrome.i18n.getMessage( 'validateHowMany' )
		false

	if !settings.security.lowercase && !settings.security.uppercase && !settings.security.special && !settings.security.punctuation
		if notify
			throwError window.chrome.i18n.getMessage( 'validateComplexity' )
		false

	true

# Function: Apply Settings
applySettings = () ->
	# Enable single/multiple according to settings
	if paGenSettings.type == 'single'
		document.getElementById('generator-form').getElementsByClassName('single')[0].style.display = 'block'
		document.getElementById('generator-form').getElementsByClassName('multiple')[0].style.display = 'none'
		document.getElementById('main-screen').style.height = windowHeights.single
		document.getElementById('settingsSingle').checked = true
		document.getElementById('settingsMultiple').checked = false
	else
		document.getElementById('generator-form').getElementsByClassName('multiple')[0].style.display = 'block'
		document.getElementById('generator-form').getElementsByClassName('single')[0].style.display = 'none'
		document.getElementById('main-screen').style.height = windowHeights.multiple
		document.getElementById('settingsMultiple').checked = true
		document.getElementById('settingsSingle').checked = false

	# Update password length and number of passwords
	document.getElementById('single-passwords-length').value = paGenSettings.chars
	document.getElementById('multiple-passwords-length').value = paGenSettings.chars
	document.getElementById('passwords-number').value = paGenSettings.howmany

	# Update settings
	document.getElementById('settingsLowercase').checked = paGenSettings.security.lowercase
	document.getElementById('settingsUppercase').checked = paGenSettings.security.uppercase
	document.getElementById('settingsSpecial').checked = paGenSettings.security.special
	document.getElementById('settingsPunctuation').checked = paGenSettings.security.punctuation
	document.getElementById('settingsReadable').checked = paGenSettings.security.readable

	# Focus correct element
	if paGenSettings.type == 'single'
		document.getElementById('single-passwords-length').focus()
	else
		document.getElementById('multiple-passwords-length').focus()

	true

# Function: Save Settings
saveSettings = (settings, notify) ->
	if validateSettings settings, true
		# Save settings using the Chrome extension storage API. Try sync, fallback to local
		window.chrome.storage.sync.set { settings: settings }, () ->
			if chrome.runtime.lastError && chrome.runtime.lastError.message && chrome.runtime.lastError.message.indexOf 'MAX_WRITE_OPERATIONS_PER_HOUR' != false
				window.chrome.storage.local.set { settings: settings }, () ->
					paGenSettings = settings

					if notify
						showNotification window.chrome.i18n.getMessage( 'settingsSaved' )

					applySettings()

					true
			else
				paGenSettings = settings

				if notify
					showNotification window.chrome.i18n.getMessage( 'settingsSaved' )

				applySettings()

				true
		true
	else
		false

# Function: Get Settings
getSettings = () ->
	# Get settings using the Chrome extension storage API. Try sync, fallback to local
	window.chrome.storage.sync.get 'settings', (items) ->
		if items.settings
			settings = extend( paGenSettings, items.settings)

			if validateSettings settings, false
				paGenSettings = settings

				applySettings()
			true
		else
			window.chrome.storage.local.get 'settings', (items) ->
				if items.settings
					settings = extend( paGenSettings, items.settings)

					if validateSettings settings, false
						paGenSettings = settings
				applySettings()
			true

# Function: Get and return Settings from the Forms
getSettingsFromHTML = () ->
	parsedSettings = {}

	if document.getElementById('settingsSingle').checked
		parsedSettings.type = 'single'
	else
		parsedSettings.type = 'multiple'

	if parsedSettings.type == 'single'
		parsedSettings.chars = window.parseInt document.getElementById('single-passwords-length').value
		parsedSettings.howmany = 1
	else
		parsedSettings.chars = window.parseInt document.getElementById('multiple-passwords-length').value
		parsedSettings.howmany = window.parseInt document.getElementById('passwords-number').value

	parsedSettings.security = {}

	parsedSettings.security.lowercase = document.getElementById('settingsLowercase').checked
	parsedSettings.security.uppercase = document.getElementById('settingsUppercase').checked
	parsedSettings.security.special = document.getElementById('settingsSpecial').checked
	parsedSettings.security.punctuation = document.getElementById('settingsPunctuation').checked
	parsedSettings.security.readable = document.getElementById('settingsReadable').checked

	parsedSettings

# Function: Generate random string
generateRandomString = (stringLength, possibleChars) ->
	randomString = []
	i = 0

	while i < stringLength
		randomPosition = Math.floor( Math.random() * possibleChars.length )
		randomString.push possibleChars.substring(randomPosition, randomPosition + 1)
		++i

	randomString.join('')

# Function: Generate Password
generatePassword = (settings) ->
	generatedPasswords = []

	if !settings || !validateSettings( settings, false )
		settings = paGenSettings

	charPossibilities = []
	# Define character possibilities according to complexity
	if settings.security.lowercase
		if settings.security.readable
			charPossibilities.push 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz'
		else
			charPossibilities.push 'abcdefghijklmnopqrstuvwxyz'

	if settings.security.uppercase
		if settings.security.readable
			charPossibilities.push 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'
		else
			charPossibilities.push 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

	if settings.security.special
		if settings.security.readable
			charPossibilities.push 'áÁéÉàÀèÈçÇ'
		else
			charPossibilities.push 'áÁéÉíÍóÓúÚàÀèÈìÌòÒùÙäÄëËïÏöÖüÜçÇ'

	if settings.security.punctuation
		if settings.security.readable
			charPossibilities.push '!.,;:?#&*%-'
		else
			charPossibilities.push '!.,;:?^~`´<>”·ˆ‹›#&*%-()[]{}'

	charPossibilities = charPossibilities.join('').shuffle()

	# Generate
	i = 0
	while i < settings.howmany
		generatedPasswords.push generateRandomString( settings.chars, charPossibilities )
		++i

	# Display
	if settings.type == 'single'
		document.getElementById('password-input').value = generatedPasswords.join('')
	else
		document.getElementById('passwords-textarea').value = generatedPasswords.join("\n")
	true

# Function: Add an EventListener to a nodeList
addEventListenerToList = (nodeList, event, fn) ->
	nodeListElement.addEventListener event, fn, false for nodeListElement in nodeList
	true

## EVENT LISTENERS ##

# Chrome Listener: Save & Apply Settings whenever a sync is made
window.chrome.storage.onChanged.addListener (changes, namespace) ->
	if namespace == 'sync'
		for key of changes
			if key == 'settings'
				settings = extend( paGenSettings, changes[key] )

		if settings
			saveSettings settings, false
	true

# EventListener: Disable generator-form submit
document.getElementById('generator-form').addEventListener 'submit', (event) ->
	event.preventDefault()
	false

# EventListener: Disable settings-form submit
document.getElementById('settings-form').addEventListener 'submit', (event) ->
	event.preventDefault()
	false

# EventListener: Settings cog button
document.getElementById('settings-cog').addEventListener 'click', (event) ->
	event.preventDefault()
	document.getElementById('main-screen').style.height = '0px'
	hideScreen = () ->
		document.getElementById('main-screen').style.display = 'none'
		true
	window.setTimeout hideScreen, 300
	document.getElementById('settings-screen').style.display = 'block'
	document.getElementById('settings-screen').style.height = '0px'
	setScreenHeight = () ->
		document.getElementById('settings-screen').style.height = windowHeights.settings
		true
	window.setTimeout setScreenHeight, 10
	true

# EventListener: Go Back button
addEventListenerToList document.getElementById('settings-screen').getElementsByClassName('go-back'), 'click', (event) ->
	event.preventDefault()
	document.getElementById('settings-screen').style.height = '0px'
	hideScreen = () ->
		document.getElementById('settings-screen').style.display = 'none'
		true
	window.setTimeout hideScreen, 300
	document.getElementById('main-screen').style.display = 'block'
	document.getElementById('main-screen').style.height = '0px'
	setScreenHeight = () ->
		if paGenSettings.type == 'single'
			document.getElementById('main-screen').style.height = windowHeights.single
		else
			document.getElementById('main-screen').style.height = windowHeights.multiple
		true
	window.setTimeout setScreenHeight, 10
	true

# EventListener: Save Settings button
document.getElementById('save-settings').addEventListener 'click', (event) ->
	event.preventDefault()

	settings = getSettingsFromHTML()

	if saveSettings( settings, true )
		document.getElementById('settings-screen').getElementsByClassName('go-back')[0].click()
	true

# EventListener: Generate Password(s) button
addEventListenerToList document.getElementsByClassName('generate-password'), 'click', (event) ->
	event.preventDefault()

	settings = getSettingsFromHTML()

	saveSettings settings, false

	generatePassword settings

	true

# Event: Get, Validate and Apply Settings
getSettings()

# Event: Apply i18n
applyi18n()