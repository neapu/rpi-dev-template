cmake_minimum_required(VERSION 3.30)
project(rpi-dev)

set(CMAKE_CXX_STANDARD 23)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/../bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/../bin)

find_package(Qt6 COMPONENTS Quick REQUIRED)

qt_add_executable(${PROJECT_NAME} main.cpp)

qt_add_resources(rpi-dev "qml" 
    PREFIX "/" 
    FILES 
        qml/Main.qml
)

target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Quick)

set_target_properties(${PROJECT_NAME} PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "$ORIGIN/lib"
)

add_custom_target(deploy-rpi-dev ALL
    COMMAND ${CMAKE_COMMAND}
        "-DQT_CORE_LIBRARY=$<TARGET_FILE:Qt6::Core>"
        "-DDESTINATION=$<TARGET_FILE_DIR:rpi-dev>"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/deploy-qt.cmake"
    DEPENDS ${PROJECT_NAME}
    VERBATIM
)