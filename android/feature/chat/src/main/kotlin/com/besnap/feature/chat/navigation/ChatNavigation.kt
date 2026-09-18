package com.besnap.feature.chat.navigation

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavOptions
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.besnap.feature.chat.ui.ChatRoute

const val CHAT_ROUTE_PREFIX = "chat_route"
const val CONVERSATION_ID_ARG = "conversationId"

fun NavController.navigateToChat(conversationId: String, navOptions: NavOptions? = null) {
    this.navigate("$CHAT_ROUTE_PREFIX/$conversationId", navOptions)
}

fun NavGraphBuilder.chatScreen(
    onBackClick: () -> Unit
) {
    composable(
        route = "$CHAT_ROUTE_PREFIX/{$CONVERSATION_ID_ARG}",
        arguments = listOf(navArgument(CONVERSATION_ID_ARG) { type = NavType.StringType })
    ) {
        ChatRoute(
            onBackClick = onBackClick
        )
    }
}
