cmake_minimum_required(VERSION 3.16)
project(imgui_coding_party___tetris)

if (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    add_compile_definitions(OS_WINDOWS)
    add_compile_definitions(NOMINMAX)

    set(CONFIG_OS_WINDOWS 1)
    if (MSVC)
        set(OPTIONS WIN32)
        add_compile_definitions(USE_WINMAIN)
    endif(MSVC)

    set(THREADS_LIBRARIES)

elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    add_compile_definitions(OS_LINUX)
    set(CONFIG_OS_LINUX 1)

    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
    set(THREADS_LIBRARIES Threads::Threads)

else()
    message(FATAL_ERROR "unsupported OS")

endif()

set(COMPILE_SFML_WITH_PROJECT ON)

include(cmake/imgui-sfml.cmake)

add_executable(imgui_coding_party___tetris imdrawlist_party.cpp main.cpp)

set_target_properties(
        imgui_coding_party___tetris PROPERTIES
        CXX_STANDARD 98
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
)

target_include_directories(imgui_coding_party___tetris SYSTEM PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}/external/imgui
        ${CMAKE_CURRENT_LIST_DIR}/external/imgui-sfml
        ${CMAKE_CURRENT_LIST_DIR}/external/sfml/include)

target_link_libraries(
        imgui_coding_party___tetris
        ${IMGUI_SFML_LIBRARIES}
        ${SFML_LIBRARIES}
        ${THREADS_LIBRARIES}
)

message(STATUS sfml ${SFML_LIBRARIES} -- imgui ${IMGUI_SFML_LIBRARIES})
