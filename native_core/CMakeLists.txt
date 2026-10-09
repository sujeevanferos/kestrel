cmake_minimum_required(VERSION 3.16)
project(kestrel_core VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

set(SOURCES
    src/stroke_processor.cpp
)

# Shared library for Dart FFI / Android JNI
add_library(kestrel_core SHARED ${SOURCES})

target_compile_definitions(kestrel_core PRIVATE KESTREL_EXPORTS)

if(WIN32)
    set_target_properties(kestrel_core PROPERTIES
        OUTPUT_NAME "kestrel_core"
        WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif()

# Automated unit test executable
add_executable(test_stroke_processor
    test/test_stroke_processor.cpp
    src/stroke_processor.cpp
)
target_include_directories(test_stroke_processor PRIVATE include)
