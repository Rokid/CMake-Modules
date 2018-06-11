include(CMakeParseArguments)

# params:
#   HINTS
#   INC_PATH_SUFFIX
#   LIB_PATH_SUFFIX
#   HEADER
#   RPATH <path>|default
#   RPATH_LINK <path>|default
#   STATIC_LIBS
#   SHARED_LIBS
function (findPackage name)

# parse arguments, rfp(rokid find package)
set(options REQUIRED)
set(oneValueArgs HEADER INC_PATH_SUFFIX LIB_PATH_SUFFIX RPATH RPATH_LINK)
set(multiValueArgs STATIC_LIBS SHARED_LIBS HINTS)
cmake_parse_arguments(rfp "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

if (rfp_REQUIRED)
set (logprio FATAL_ERROR)
else()
set (logprio STATUS)
endif()
if (NOT rfp_HINTS)
set(rfp_HINTS /usr)
endif()
if (NOT rfp_STATIC_LIBS AND NOT rfp_SHARED_LIBS)
message(${logprio} "findPackage ${name} not specified STATIC_LIBS|SHARED_LIBS")
endif()
if (rfp_INC_PATH_SUFFIX)
set(incPathSuffix ${rfp_INC_PATH_SUFFIX})
else()
set(incPathSuffix include)
endif()
if (rfp_LIB_PATH_SUFFIX)
set(libPathSuffix ${rfp_LIB_PATH_SUFFIX})
else()
set(libPathSuffix lib)
endif()


unset(rootDir CACHE)
find_path(rootDir NAMES ${incPathSuffix}/${rfp_HEADER} HINTS ${rfp_HINTS})
if (NOT rootDir)
	message(${logprio} "${name}: Could not find package root dir: header file ${incPathSuffix}/${rfp_HEADER} not found, HINTS ${rfp_HINTS}")
	return()
endif()

foreach (lib IN LISTS rfp_STATIC_LIBS)
	unset(libPathName CACHE)
	find_library(
		libPathName
		NAMES lib${lib}.a
		HINTS ${rootDir}
		PATH_SUFFIXES ${libPathSuffix}
	)

	if (libPathName)
		set(ldflags "${ldflags} -l${lib}")
		set(st_found true)
	else()
		message(${logprio} "Not Found ${name}: lib${lib}.a. HINTS ${rootDir} LIB_PATH_SUFFIX ${libPathSuffix}")
	endif()
endforeach()

foreach (lib IN LISTS rfp_SHARED_LIBS)
	unset(libPathName CACHE)
	find_library(
		libPathName
		NAMES ${lib}
		HINTS ${rootDir}
		PATH_SUFFIXES ${libPathSuffix}
	)

	if (libPathName)
		set(sh_found true)
		set(ldflags "${ldflags} -l${lib}")
	else()
		message(${logprio} "Not Found ${name}: ${lib}. HINTS ${rootDir} LIB_PATH_SUFFIX ${libPathSuffix}")
	endif()
endforeach()

if (sh_found)
if (rfp_RPATH)
if (rfp_RPATH STREQUAL default)
set(rpathFlags "-Wl,-rpath=${rootDir}/${libPathSuffix}")
else()
set(rpathFlags "-Wl,-rpath=${rfp_RPATH}")
endif()
endif(rfp_RPATH)
if (rfp_RPATH_LINK)
if (rfp_RPATH_LINK STREQUAL default)
set(rpathFlags "${rpathFlags} -Wl,-rpath-link=${rootDir}/${libPathSuffix}")
else()
set(rpathFlags "${rpathFlags} -Wl,-rpath-link=${rfp_RPATH_LINK}")
endif()
endif(rfp_RPATH_LINK)
endif(sh_found)
if (rootDir)
	set(${name}_INCLUDE_DIR ${rootDir}/${incPathSuffix} PARENT_SCOPE)
endif()
if (sh_found OR st_found)
	set(result_libraries "-L${rootDir}/${libPathSuffix} ${ldflags}")
	if (rpathFlags)
		set(result_libraries "${result_libraries} ${rpathFlags}")
	endif()
	set(${name}_LIBRARIES ${result_libraries} PARENT_SCOPE)
	if (rpathFlags)
		set(${name}_LIBRARIES "-L${rootDir}/${libPathSuffix} ${ldflags} ${rpathFlags}" PARENT_SCOPE)
	else()
		set(${name}_LIBRARIES "-L${rootDir}/${libPathSuffix} ${ldflags}" PARENT_SCOPE)
	endif()
	message(STATUS "Found ${name}: ${result_libraries}")
	set (${name}_FOUND TRUE PARENT_SCOPE)
endif()
endfunction()
