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
        path: 'expression',
        loadChildren: () => import('src/app/modules/expression/expression.module').then((m) => m.ExpressionModule),
      },
      {
        path: 'mutation',
        loadChildren: () => import('src/app/modules/mutation/mutation.module').then((m) => m.MutationModule),
      },
      {
        path: 'immune',
        loadChildren: () => import('src/app/modules/immune/immune.module').then((m) => m.ImmuneModule),
      },
      {
        path: 'drug',
        loadChildren: () => import('src/app/modules/drug/drug.module').then((m) => m.DrugModule),
      },
      {
        path: 'document',
        loadChildren: () => import('src/app/modules/document/document.module').then((m) => m.DocumentModule),
      },
      {
        path: 'contact',
        loadChildren: () => import('src/app/modules/contact/contact.module').then((m) => m.ContactModule),
      },
      {
        path: 'terms',
        loadChildren: () => import('src/app/modules/terms/terms.module').then((m) => m.TermsModule),
      },
      {
        path: 'download-page',
        loadChildren: () => import('src/app/modules/download-page/download-page.module').then((m) => m.DownloadPageModule),
      },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class DefaultRoutingModule {}
