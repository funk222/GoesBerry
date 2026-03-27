import { createRouter, createWebHistory } from 'vue-router';
import Latest    from '../views/Latest.vue';
import History   from '../views/History.vue';
import Animation from '../views/Animation.vue';
import Status    from '../views/Status.vue';

const routes = [
  { path: '/',           redirect: '/latest' },
  { path: '/latest',     component: Latest,    meta: { title: 'Latest' } },
  { path: '/history',    component: History,   meta: { title: 'History' } },
  { path: '/animation',  component: Animation, meta: { title: 'Animation' } },
  { path: '/status',     component: Status,    meta: { title: 'Status' } },
];

export default createRouter({
  history: createWebHistory(),
  routes,
});
