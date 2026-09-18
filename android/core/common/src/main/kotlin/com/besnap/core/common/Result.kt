package com.besnap.core.common

sealed interface BeSnapResult<out T> {
    data class Success<T>(val data: T) : BeSnapResult<T>
    data class Error(val message: String, val throwable: Throwable? = null) : BeSnapResult<Nothing>
    data object Loading : BeSnapResult<Nothing>
}
