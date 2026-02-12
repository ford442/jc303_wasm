cmake_minimum_required(VERSION 3.15)
project(JC303_WASM VERSION 0.12.3)

# C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Emscripten check
if(NOT EMSCRIPTEN)
    message(FATAL_ERROR "This CMakeLists.txt is intended for Emscripten builds only. Use: emcmake cmake ..")
endif()

# Source files from Open303 DSP engine
set(OPEN303_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/GlobalFunctions.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_AcidPattern.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_AcidSequencer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_AnalogEnvelope.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_BiquadFilter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_BlendOscillator.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_Complex.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_DecayEnvelope.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_EllipticQuarterBandFilter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_FourierTransformerRadix2.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_FunctionTemplates.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_LeakyIntegrator.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_MidiNoteEvent.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_MipMappedWaveTable.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_NumberManipulations.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_OnePoleFilter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_Open303.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_RealFunctions.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303/rosic_TeeBeeFilter.cpp
)

# WASM wrapper source
set(WASM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/jc303_wasm.cpp
)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/dsp/open303
)

# Create the WASM executable
add_executable(jc303 ${OPEN303_SOURCES} ${WASM_SOURCES})

# Option to enable extra Emscripten debug flags (SAFE_HEAP / ASSERTIONS / -g)
option(ENABLE_WASM_DEBUG "Enable Emscripten debug flags (SAFE_HEAP/ASSERTIONS and -g)" OFF)

if(ENABLE_WASM_DEBUG)
    # Use list for proper space-separated argument handling
    set(EMCC_LINK_FLAGS_LIST
        -s WASM=1
        -s MODULARIZE=1
        -s EXPORT_NAME=JC303Module
        -s "EXPORTED_FUNCTIONS=[\"_malloc\",\"_free\"]"
        -s "EXPORTED_RUNTIME_METHODS=[\"ccall\",\"cwrap\",\"getValue\",\"setValue\",\"HEAPF32\"]"
        -s ALLOW_MEMORY_GROWTH=1
        -s INITIAL_MEMORY=16777216
        -s STACK_SIZE=2097152
        -s NO_EXIT_RUNTIME=1
        -s ENVIRONMENT=web,worker
        -s SINGLE_FILE=0
        --bind
        --pre-js ${CMAKE_CURRENT_SOURCE_DIR}/early_wasm_table.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/compat_wasm_imports.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/safe_unbound_types.js
        -O0
        -g
        -sASSERTIONS=2
        -sSAFE_HEAP=1
    )
    string(REPLACE ";" " " EMCC_LINK_FLAGS "${EMCC_LINK_FLAGS_LIST}")
    
    set(EMCC_COMPILE_OPTIONS
        -O0
        -g
        -fno-exceptions
        -fno-rtti
        -DEMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0
    )
else()
    # Use list for proper space-separated argument handling
    set(EMCC_LINK_FLAGS_LIST
        -s WASM=1
        -s MODULARIZE=1
        -s EXPORT_NAME=JC303Module
        -s "EXPORTED_FUNCTIONS=[\"_malloc\",\"_free\"]"
        -s "EXPORTED_RUNTIME_METHODS=[\"ccall\",\"cwrap\",\"getValue\",\"setValue\",\"HEAPF32\"]"
        -s ALLOW_MEMORY_GROWTH=1
        -s INITIAL_MEMORY=16777216
        -s STACK_SIZE=2097152
        -s NO_EXIT_RUNTIME=1
        -s ENVIRONMENT=web,worker
        -s SINGLE_FILE=0
        --bind
        --pre-js ${CMAKE_CURRENT_SOURCE_DIR}/early_wasm_table.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/compat_wasm_imports.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/safe_unbound_types.js
        -O3
        -flto
    )
    string(REPLACE ";" " " EMCC_LINK_FLAGS "${EMCC_LINK_FLAGS_LIST}")
    
    set(EMCC_COMPILE_OPTIONS
        -O3
        -flto
        -fno-exceptions
        -fno-rtti
        -DEMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0
    )
endif()

set_target_properties(jc303 PROPERTIES
    SUFFIX ".js"
    LINK_FLAGS "${EMCC_LINK_FLAGS}"
)

# Compiler flags
target_compile_options(jc303 PRIVATE ${EMCC_COMPILE_OPTIONS})

# Create a separate AudioWorklet-compatible module
add_executable(jc303_worklet ${OPEN303_SOURCES} ${WASM_SOURCES})

if(ENABLE_WASM_DEBUG)
    # Use list for proper space-separated argument handling
    set(EMCC_WORKLET_LINK_FLAGS_LIST
        -s WASM=1
        -s MODULARIZE=1
        -s EXPORT_NAME=JC303WorkletModule
        -s "EXPORTED_FUNCTIONS=[\"_malloc\",\"_free\"]"
        -s "EXPORTED_RUNTIME_METHODS=[\"ccall\",\"cwrap\",\"getValue\",\"setValue\",\"HEAPF32\"]"
        -s ALLOW_MEMORY_GROWTH=1
        -s INITIAL_MEMORY=16777216
        -s STACK_SIZE=2097152
        -s NO_EXIT_RUNTIME=1
        -s ENVIRONMENT=worker
        -s SINGLE_FILE=1
        --bind
        --pre-js ${CMAKE_CURRENT_SOURCE_DIR}/early_wasm_table.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/compat_wasm_imports.js
        -O0
        -g
        -sASSERTIONS=2
        -sSAFE_HEAP=1
    )
    string(REPLACE ";" " " EMCC_WORKLET_LINK_FLAGS "${EMCC_WORKLET_LINK_FLAGS_LIST}")
    
    set(EMCC_WORKLET_COMPILE_OPTIONS
        -O0
        -g
        -fno-exceptions
        -fno-rtti
        -DEMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0
    )
else()
    # Use list for proper space-separated argument handling
    set(EMCC_WORKLET_LINK_FLAGS_LIST
        -s WASM=1
        -s MODULARIZE=1
        -s EXPORT_NAME=JC303WorkletModule
        -s "EXPORTED_FUNCTIONS=[\"_malloc\",\"_free\"]"
        -s "EXPORTED_RUNTIME_METHODS=[\"ccall\",\"cwrap\",\"getValue\",\"setValue\",\"HEAPF32\"]"
        -s ALLOW_MEMORY_GROWTH=1
        -s INITIAL_MEMORY=16777216
        -s STACK_SIZE=2097152
        -s NO_EXIT_RUNTIME=1
        -s ENVIRONMENT=worker
        -s SINGLE_FILE=1
        --bind
        --pre-js ${CMAKE_CURRENT_SOURCE_DIR}/early_wasm_table.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/compat_wasm_imports.js
        --post-js ${CMAKE_CURRENT_SOURCE_DIR}/safe_unbound_types.js
        -O3
        -flto
    )
    string(REPLACE ";" " " EMCC_WORKLET_LINK_FLAGS "${EMCC_WORKLET_LINK_FLAGS_LIST}")
    
    set(EMCC_WORKLET_COMPILE_OPTIONS
        -O3
        -flto
        -fno-exceptions
        -fno-rtti
        -DEMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0
    )
endif()

set_target_properties(jc303_worklet PROPERTIES
    SUFFIX ".js"
    LINK_FLAGS "${EMCC_WORKLET_LINK_FLAGS}"
)

target_compile_options(jc303_worklet PRIVATE ${EMCC_WORKLET_COMPILE_OPTIONS})

# Installation rules
install(FILES
    ${CMAKE_BINARY_DIR}/jc303.js
    ${CMAKE_BINARY_DIR}/jc303.wasm
    ${CMAKE_BINARY_DIR}/jc303_worklet.js
    DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/dist
)
