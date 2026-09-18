package com.besnap.core.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.besnap.core.database.dao.UserDao
import com.besnap.core.database.model.UserEntity

@Database(entities = [UserEntity::class], version = 1, exportSchema = false)
abstract class BeSnapDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
}
