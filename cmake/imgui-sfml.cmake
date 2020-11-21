function(missing_external varout dependency)
    get_filename_component(dir_path "${CMAKE_SOURCE_DIR}/external/${dependency}" REALPATH)
    if(EXISTS "${dir_path}")
        if(IS_DIRECTORY "${dir_path}")
            file(GLOB files "${dir_path}/*")
            list(LENGTH files len)
            if(len EQUAL 0)
                set(varout true PARENT_SCOPE)
            endif()
        else()
            set(varout true PARENT_SCOPE)
        endif()
    else()
        set(varout true PARENT_SCOPE)
    endif()
    set(varout false PARENT_SCOPE)
endfunction()

function(target_set_output_directory target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "Invalid argument: ${target} is not a target")
    endif()
    cmake_parse_arguments(ARGS "" "RUNTIME;LIBRARY;ARCHIVE" "" ${ARGN})
    if(NOT (ARGS_RUNTIME OR ARGS_LIBRARY OR ARGS_ARCHIVE))
        if(${ARGC} GREATER 2)
            message(FATAL_ERROR "Invalid arguments")
        endif()
        set(ARGS_RUNTIME ${ARGS_UNPARSED_ARGUMENTS})
        set(ARGS_LIBRARY ${ARGS_UNPARSED_ARGUMENTS})
        set(ARGS_ARCHIVE ${ARGS_UNPARSED_ARGUMENTS})
    else()
        if(ARGS_UNPARSED_ARGUMENTS)
            message(FATAL_ERROR "Invalid arguments: ${ARGS_UNPARSED_ARGUMENTS}")
        endif()
    endif()

    foreach(type IN ITEMS RUNTIME LIBRARY ARCHIVE)
        if(ARGS_${type})
            set_target_properties(${target} PROPERTIES ${type}_OUTPUT_DIRECTORY ${ARGS_${type}})
            foreach(mode IN ITEMS DEBUG RELWITHDEBINFO RELEASE)
                set_target_properties(${target} PROPERTIES ${type}_OUTPUT_DIRECTORY_${mode} ${ARGS_${type}})
            endforeach()
        endif()
    endforeach()
endfunction()

function(configure_folder input_folder output_folder)
    if(NOT EXISTS ${output_folder})
        file(MAKE_DIRECTORY ${output_folder})
    endif()
    file(GLOB_RECURSE files "${input_folder}/*")
    foreach(file ${files})
        file(RELATIVE_PATH relative_file ${input_folder} ${file})
        configure_file(${file} "${output_folder}/${relative_file}" ${ARGN})
    endforeach()
endfunction()

function(split_args left delimiter right)
    set(delimiter_found false)
    set(tmp_left)
    set(tmp_right)
    foreach(it ${ARGN})
        if("${it}" STREQUAL ${delimiter})
            set(delimiter_found true)
        elseif(delimiter_found)
            list(APPEND tmp_right ${it})
        else()
            list(APPEND tmp_left ${it})
        endif()
    endforeach()
    set(${left} ${tmp_left} PARENT_SCOPE)
    set(${right} ${tmp_right} PARENT_SCOPE)
endfunction()

function(has_item output item)
    set(tmp_output false)
    foreach(it ${ARGN})
        if("${it}" STREQUAL "${item}")
            set(tmp_output true)
            break()
        endif()
    endforeach()
    set(${output} ${tmp_output} PARENT_SCOPE)
endfunction()

function(group_files group root)
    foreach(it ${ARGN})
        get_filename_component(dir ${it} PATH)
        file(RELATIVE_PATH relative ${root} ${dir})
        set(local ${group})
        if(NOT "${relative}" STREQUAL "")
            set(local "${group}/${relative}")
        endif()
        # replace '/' and '\' (and repetitions) by '\\'
        string(REGEX REPLACE "[\\\\\\/]+" "\\\\\\\\" local ${local})
        source_group("${local}" FILES ${it})
    endforeach()
endfunction()

function(get_files output)
    split_args(dirs "OPTIONS" options ${ARGN})
    set(glob GLOB)
    has_item(has_recurse "recurse" ${options})
    if(has_recurse)
        set(glob GLOB_RECURSE)
    endif()
    set(files)
    foreach(it ${dirs})
        if(IS_DIRECTORY ${it})
            set(patterns
                    "${it}/*.c"
                    "${it}/*.cc"
                    "${it}/*.cpp"
                    "${it}/*.cxx"
                    "${it}/*.h"
                    "${it}/*.hpp"
                    )
            file(${glob} tmp_files ${patterns})
            list(APPEND files ${tmp_files})
            get_filename_component(parent_dir ${it} DIRECTORY)
            group_files(Sources "${parent_dir}" ${tmp_files})
        else()
            list(APPEND files ${it})
            get_filename_component(dir ${it} DIRECTORY)
            group_files(Sources "${dir}" ${it})
        endif()
    endforeach()
    set(${output} ${files} PARENT_SCOPE)
endfunction()

message(STATUS "Configuring OpenGL")

set(OpenGL_GL_PREFERENCE "LEGACY")
find_package(OpenGL REQUIRED)

if(NOT OPENGL_FOUND)
    message(FATAL_ERROR "OpenGL not found")
    return()
endif()

set(OPENGL_INCLUDE_DIR   ${OPENGL_INCLUDE_DIRS})
set(OPENGL_LIBRARIES       ${OPENGL_gl_LIBRARY})

# Message
message(STATUS "Configuring OpenGL - Done")

message(STATUS "Configuring SFML")

if(NOT COMPILE_SFML_WITH_PROJECT)
    if(CONFIG_OS_WINDOWS)
        set(COMPILE_SFML_WITH_PROJECT ON)
        message(STATUS "OS is Windows, SFML will be compiled with project")
    else()
        find_package(SFML ${SFML_MINIMUM_SYSTEM_VERSION} COMPONENTS system window graphics audio CONFIG)
        if(SFML_FOUND)
            # Variables
            set(SFML_INCLUDE_DIR  "")
            set(SFML_LIBRARIES sfml-system sfml-window sfml-graphics sfml-audio)
            message(STATUS "Configuring SFML - done")
        else()
            set(COMPILE_SFML_WITH_PROJECT ON)
            message(STATUS "SFML system installation not found, compile SFML with project")
        endif()
    endif()
endif()

if(COMPILE_SFML_WITH_PROJECT)
    get_filename_component(SFML_DIR ${CMAKE_SOURCE_DIR}/external/sfml ABSOLUTE)

    # Submodule check
    missing_external(missing SFML)
    if(missing)
        message(FATAL_ERROR "SFML dependency is missing, maybe you didn't pull the git submodules")
    endif()

    # Subproject
    add_subdirectory(${SFML_DIR})

    # Configure SFML folder in IDE
    foreach(sfml_target IN ITEMS sfml-system sfml-network sfml-window sfml-graphics sfml-audio sfml-main)
        if(TARGET ${sfml_target})
            set_target_properties(${sfml_target} PROPERTIES FOLDER external/sfml)
        endif()
    endforeach()

    # Configure OpenAL
    if(CONFIG_OS_WINDOWS)
        set(ARCH_FOLDER "x86")
        if(CONFIG_ARCH_64)
            set(ARCH_FOLDER "x64")
        endif()
        configure_file(${SFML_DIR}/extlibs/bin/${ARCH_FOLDER}/openal32.dll ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} COPYONLY)
    endif()

    # Setup targets output, put exe and required SFML dll in the same folder
    target_set_output_directory(sfml-system "${CMAKE_BINARY_DIR}")
    target_set_output_directory(sfml-window "${CMAKE_BINARY_DIR}")
    target_set_output_directory(sfml-graphics "${CMAKE_BINARY_DIR}")
    target_set_output_directory(sfml-audio "${CMAKE_BINARY_DIR}")

    get_filename_component(SFML_INCLUDE_DIR  ${SFML_DIR}/include  ABSOLUTE)
    set(SFML_LIBRARIES sfml-system sfml-window sfml-graphics sfml-audio)

    if(CONFIG_OS_LINUX)
        set(SFML_LIBRARIES ${SFML_LIBRARIES} X11)
    endif()
    message(STATUS "Configuring SFML - Done")
endif()

########################################################################################################################

message(STATUS "Configuring imgui-sfml")

get_filename_component(IMGUI_DIR ${CMAKE_SOURCE_DIR}/external/ImGui ABSOLUTE)
get_filename_component(IMGUI_SFML_DIR ${CMAKE_SOURCE_DIR}/external/ImGui-SFML ABSOLUTE)
get_filename_component(IMGUI_SFML_TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR}/ImGui-SFML ABSOLUTE)

# Submodules check
missing_external(missing ImGui)
if(missing)
    message(FATAL_ERROR "ImGui dependency is missing, maybe you didn't pull the git submodules")
endif()
missing_external(missing ImGui-SFML)
if(missing)
    message(FATAL_ERROR "imgui-sfml dependency is missing, maybe you didn't pull the git submodules")
endif()

# Copy imgui and imgui-sfml files to cmake build folder
configure_folder(${IMGUI_DIR} ${IMGUI_SFML_TARGET_DIR} COPYONLY)
configure_folder(${IMGUI_SFML_DIR} ${IMGUI_SFML_TARGET_DIR} COPYONLY)

# Include imgui-sfml config header in imgui config header
file(APPEND "${IMGUI_SFML_TARGET_DIR}/imconfig.h" "\n#include \"imconfig-SFML.h\"\n")

# Setup target
get_files(files "${IMGUI_SFML_TARGET_DIR}")
add_library(imgui-sfml STATIC ${files})
target_include_directories(imgui-sfml SYSTEM PRIVATE "${SFML_INCLUDE_DIR}" "${IMGUI_SFML_TARGET_DIR}")

target_link_libraries(imgui-sfml PRIVATE "${SFML_LIBRARIES}" "${OPENGL_LIBRARIES}")
target_compile_definitions(imgui-sfml PUBLIC IMGUI_DISABLE_OBSOLETE_FUNCTIONS)

# Variables
get_filename_component(IMGUI_SFML_INCLUDE_DIR  "${IMGUI_SFML_TARGET_DIR}"  ABSOLUTE)
set(IMGUI_SFML_LIBRARIES imgui-sfml)

# Message
message(STATUS "Configuring imgui-sfml - Done")