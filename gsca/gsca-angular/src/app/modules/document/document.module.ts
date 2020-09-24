import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DocumentRoutingModule } from './document-routing.module';
import { DocumentComponent } from './document.component';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [DocumentComponent],
  imports: [CommonModule, DocumentRoutingModule, SharedModule],
})
export class DocumentModule {}
