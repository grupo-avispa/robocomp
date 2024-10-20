IF (NOT QT.CMAKE)
	set (QT.CMAKE TRUE)
	# QT
	option (USE_QT5 "Build with QT5" ON)
	option (USE_QT4 "Build with QT4" OFF)

	# Default => Qt5 if not found tries with Qt4
	IF (USE_QT5)
		find_package(Qt5 COMPONENTS Core)
		IF (NOT Qt5_FOUND)
			set (USE_QT5 OFF)
			set (USE_QT4 ON)
		ELSE()
			set (USE_QT5 ON)
			set (USE_QT4 OFF)
		ENDIF()
	ENDIF (USE_QT5)


	IF (USE_QT4)
		MESSAGE( STATUS "COMPILING WITH QT4" )
		find_package(Qt4 REQUIRED)
		SET( QT_USE_QTSQL TRUE )
		SET( QT_USE_QTGUI TRUE )
		SET( QT_USE_QTOPENGL TRUE )
		SET( QT_USE_QTXML TRUE )
		SET( QT_USE_QTSQL TRUE )
		SET( QT_USE_QTSTATE TRUE )
		SET( QT_USE_QTSTATEMACHINE TRUE )
		INCLUDE(${QT_USE_FILE})
		
		MACRO(QT_WRAP_CPP output )
			FOREACH( input_file ${ARGN} )
				QT4_WRAP_CPP( ${output} ${input_file} )
			ENDFOREACH( input_file)
			SET_PROPERTY(SOURCE ${${output}} PROPERTY SKIP_AUTOGEN ON)
		ENDMACRO(QT_WRAP_CPP)
		
		MACRO (QT_WRAP_UI output )
			FOREACH( input_file ${ARGN} )
				MESSAGE( STATUS "Generating header file from ${input_file}")
				QT4_WRAP_UI( ${output} ${input_file} )
			ENDFOREACH( input_file)
			SET_PROPERTY(SOURCE ${${output}} PROPERTY SKIP_AUTOGEN ON)
		ENDMACRO(QT_WRAP_UI)
		
	ENDIF (USE_QT4)

	IF (USE_QT5)
		MESSAGE( STATUS "COMPILING WITH QT5" )
		find_package(Qt5 REQUIRED COMPONENTS Gui Widgets Sql Core OpenGL Xml XmlPatterns )
		set(QT_LIBRARIES Qt5::Gui Qt5::Core Qt5::Widgets Qt5::Sql Qt5::OpenGL Qt5::Xml Qt5::XmlPatterns)
		
		MACRO(QT_WRAP_CPP output )
			FOREACH( input_file ${ARGN} )
				QT5_WRAP_CPP( ${output} ${input_file} )
			ENDFOREACH( input_file)
			SET_PROPERTY(SOURCE ${${output}} PROPERTY SKIP_AUTOGEN ON)
		ENDMACRO(QT_WRAP_CPP)
		
		MACRO (QT_WRAP_UI output )
			FOREACH( input_file ${ARGN} )
				MESSAGE( STATUS "Generating header file from ${input_file}")
				QT5_WRAP_UI( ${output} ${input_file} )
			ENDFOREACH( input_file)
			SET_PROPERTY(SOURCE ${${output}} PROPERTY SKIP_AUTOGEN ON)
		ENDMACRO(QT_WRAP_UI)
	ENDIF (USE_QT5)

	# Common
	SET( CMAKE_AUTOMOC ON )
	SET( CMAKE_AUTOUIC ON )
	ADD_DEFINITIONS( "-DBOOST_TT_HAS_OPERATOR_HPP_INCLUDED -Wall -DQT_DLL -DQT_GUI_LIB -DQT_CORE_LIB" )
	
ENDIF(NOT QT.CMAKE)
