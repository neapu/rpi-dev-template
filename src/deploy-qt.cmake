get_filename_component(qt_lib_dir "${QT_CORE_LIBRARY}" DIRECTORY)
get_filename_component(qt_prefix "${qt_lib_dir}" DIRECTORY)

file(GLOB qt_libraries "${qt_lib_dir}/libQt6*.so*")
if(NOT qt_libraries OR NOT EXISTS "${qt_prefix}/plugins/platforms"
        OR NOT EXISTS "${qt_prefix}/qml")
    message(FATAL_ERROR "Incomplete Qt runtime installation: ${qt_prefix}")
endif()

file(COPY ${qt_libraries} DESTINATION "${DESTINATION}/lib")
file(COPY "${qt_prefix}/plugins" "${qt_prefix}/qml" DESTINATION "${DESTINATION}")
file(WRITE "${DESTINATION}/qt.conf"
    "[Paths]\nPrefix=.\nLibraries=lib\nPlugins=plugins\nQmlImports=qml\n")
