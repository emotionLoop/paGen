## GLOBALS ##

# Object: Default settings
defaultSettings =
	type: 'single'
	chars: 14
	howmany: 1
	security:
		lowercase: true
		uppercase: true
		numbers: true
		special: true
		punctuation: true
		readable: false

# Object: Current settings
paGenSettings = defaultSettings

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
		return false

	if !settings.chars || isNaN settings.chars || settings.chars < 1 || settings.chars > 128
		if notify
			throwError window.chrome.i18n.getMessage( 'validateChars' )
		return false

	if !settings.howmany || isNaN settings.howmany || settings.howmany < 1 || settings.howmany > 20
		if notify
			throwError window.chrome.i18n.getMessage( 'validateHowMany' )
		return false

	if !settings.security.lowercase && !settings.security.uppercase && !settings.security.numbers && !settings.security.special && !settings.security.punctuation
		if notify
			throwError window.chrome.i18n.getMessage( 'validateComplexity' )
		return false

	true

# Function: Apply Settings
applySettings = (isItFirstLoad) ->
	# Force Boolean
	if !isItFirstLoad
		isItFirstLoad = false
	else
		isItFirstLoad = true

	# Enable single/multiple according to settings
	if paGenSettings.type == 'single'
		document.getElementById('generator-form').getElementsByClassName('single')[0].style.display = 'block'
		document.getElementById('generator-form').getElementsByClassName('multiple')[0].style.display = 'none'
		document.getElementById('settingsSingle').checked = true
		document.getElementById('settingsMultiple').checked = false
	else
		document.getElementById('generator-form').getElementsByClassName('multiple')[0].style.display = 'block'
		document.getElementById('generator-form').getElementsByClassName('single')[0].style.display = 'none'
		document.getElementById('settingsMultiple').checked = true
		document.getElementById('settingsSingle').checked = false

	# Update password length and number of passwords
	document.getElementById('single-passwords-length').value = paGenSettings.chars
	document.getElementById('multiple-passwords-length').value = paGenSettings.chars
	document.getElementById('passwords-number').value = paGenSettings.howmany

	# Update settings
	document.getElementById('settingsLowercase').checked = paGenSettings.security.lowercase
	document.getElementById('settingsUppercase').checked = paGenSettings.security.uppercase
	document.getElementById('settingsNumbers').checked = paGenSettings.security.numbers
	document.getElementById('settingsSpecial').checked = paGenSettings.security.special
	document.getElementById('settingsPunctuation').checked = paGenSettings.security.punctuation
	document.getElementById('settingsReadable').checked = paGenSettings.security.readable

	# Focus correct element on first load, this needs a timeout because of the DOM changes made by applyi18n()
	if isItFirstLoad
		if paGenSettings.type == 'single'
			window.setTimeout () ->
				document.getElementById('single-passwords-length').focus()
				true
			, 100
		else
			window.setTimeout () ->
				document.getElementById('multiple-passwords-length').focus()
				true
			, 100

	true

# Function: Save Settings
saveSettings = (settings, notify) ->
	if validateSettings( settings, true )
		# Save settings using the Chrome extension storage API. Try sync, fallback to local
		window.chrome.storage.sync.set { settings: settings }, () ->
			if window.chrome.runtime.lastError && window.chrome.runtime.lastError.message && window.chrome.runtime.lastError.message.indexOf( 'MAX_WRITE_OPERATIONS_PER_HOUR' ) != -1
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
getSettings = (isItFirstLoad) ->
	# Force Boolean
	if !isItFirstLoad
		isItFirstLoad = false
	else
		isItFirstLoad = true

	# Get settings using the Chrome extension storage API. Try sync, fallback to local
	window.chrome.storage.sync.get 'settings', (items) ->
		if items.settings
			settings = extend( paGenSettings, items.settings)

			if validateSettings settings, false
				paGenSettings = settings

				applySettings( isItFirstLoad )
			true
		else
			window.chrome.storage.local.get 'settings', (items) ->
				if items.settings
					settings = extend( paGenSettings, items.settings)

					if validateSettings settings, false
						paGenSettings = settings
				applySettings( isItFirstLoad )
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
	parsedSettings.security.numbers = document.getElementById('settingsNumbers').checked
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
			charPossibilities.push 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz'
		else
			charPossibilities.push 'abcdefghijklmnopqrstuvwxyz'

	if settings.security.uppercase
		if settings.security.readable
			charPossibilities.push 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'
		else
			charPossibilities.push 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

	if settings.security.numbers
		if settings.security.readable
			charPossibilities.push '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'
		else
			charPossibilities.push '012345678901234567890123456789'

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
	document.getElementById('main-screen').style.display = 'none'
	document.getElementById('settings-screen').style.display = 'block'
	true

# EventListener: Go Back button
addEventListenerToList document.getElementById('settings-screen').getElementsByClassName('go-back'), 'click', (event) ->
	event.preventDefault()
	document.getElementById('settings-screen').style.display = 'none'
	document.getElementById('main-screen').style.display = 'block'
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
getSettings( true )

# Event: Apply i18n
applyi18n()