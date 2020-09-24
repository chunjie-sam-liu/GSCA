import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { DefaultComponent } from './default.component';

const routes: Routes = [
  {
    path: '',
    component: DefaultComponent,
    children: [
      {
        path: '',
        loadChildren: () => import('src/app/modules/dashboard/dashboard.module').then((m) => m.DashboardModule),
      },
      {
        path: 'document',
        loadChildren: () => import('src/app/modules/document/document.module').then((m) => m.DocumentModule),
      },
      {
        path: 'contact',
        loadChildren: () => import('src/app/modules/contact/contact.module').then((m) => m.ContactModule),
      },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class DefaultRoutingModule {}
