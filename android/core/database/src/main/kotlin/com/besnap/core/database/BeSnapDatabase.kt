package com.besnap.core.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [], version = 1, exportSchema = false)
abstract class BeSnapDatabase : RoomDatabase()
