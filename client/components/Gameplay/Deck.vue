<template>
    <div v-on:click.stop="emitDeckClicked">
        {{deckSize}}
    </div>
</template>

<script>
    import { GameplayEventBus } from '../../events/GameplayEventBus.js'

    export default {
        name: "Deck",
        props: ['deckSize', 'sk'],
        data() {
            return {}
        },
        methods: {
            emitDeckClicked() {
                GameplayEventBus.$emit('deck-clicked', this);
            }
        }
    }
</script>

<style scoped>
    div {
        background-color: darkgrey;
        height: 108px;
        width: 90px;
        font-weight: bold;
        font-size: 30px;
        border: 1px solid;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        user-select: none;
    }
</style>
