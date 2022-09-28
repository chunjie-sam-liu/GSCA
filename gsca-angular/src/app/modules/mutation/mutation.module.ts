import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { MutationRoutingModule } from './mutation-routing.module';
import { MutationComponent } from './mutation.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { SearchBoxComponent } from './search-box/search-box.component';
import { SnvComponent } from './snv/snv.component';
import { SnvSurvivalComponent } from './snv-survival/snv-survival.component';
import { MethylationComponent } from './methylation/methylation.component';
import { MethySurvivalComponent } from './methy-survival/methy-survival.component';
import { MethyCorComponent } from './methy-cor/methy-cor.component';
import { CnvComponent } from './cnv/cnv.component';
import { CnvSurvivalComponent } from './cnv-survival/cnv-survival.component';
import { CnvCorComponent } from './cnv-cor/cnv-cor.component';
import { SnvGenesetSurvivalComponent } from './snv-geneset-survival/snv-geneset-survival.component';
import { CnvGenesetSurvivalComponent } from './cnv-geneset-survival/cnv-geneset-survival.component';
import { DocCnvComponent } from './cnv/doc-cnv/doc-cnv.component';
import { DocCnvCorComponent } from './cnv-cor/doc-cnv-cor/doc-cnv-cor.component';
import { DocCnvGenesetSurvivalComponent } from './cnv-geneset-survival/doc-cnv-geneset-survival/doc-cnv-geneset-survival.component';
import { DocCnvSurvivalComponent } from './cnv-survival/doc-cnv-survival/doc-cnv-survival.component';
import { DocMethyCorComponent } from './methy-cor/doc-methy-cor/doc-methy-cor.component';
import { DocMethySurvivalComponent } from './methy-survival/doc-methy-survival/doc-methy-survival.component';
import { DocMethyComponent } from './methylation/doc-methy/doc-methy.component';
import { DocSnvComponent } from './snv/doc-snv/doc-snv.component';
import { DocSnvGenesetSurvivalComponent } from './snv-geneset-survival/doc-snv-geneset-survival/doc-snv-geneset-survival.component';
import { DocSnvSurvivalComponent } from './snv-survival/doc-snv-survival/doc-snv-survival.component';
import { GsdbComponent } from './search-box/gsdb/gsdb.component';

@NgModule({
  declarations: [
    MutationComponent,
    SearchBoxComponent,
    SnvComponent,
    SnvSurvivalComponent,
    MethylationComponent,
    MethySurvivalComponent,
    MethyCorComponent,
    CnvComponent,
    CnvSurvivalComponent,
    CnvCorComponent,
    SnvGenesetSurvivalComponent,
    CnvGenesetSurvivalComponent,
    DocCnvComponent,
    DocCnvCorComponent,
    DocCnvGenesetSurvivalComponent,
    DocCnvSurvivalComponent,
    DocMethyCorComponent,
    DocMethySurvivalComponent,
    DocMethyComponent,
    DocSnvComponent,
    DocSnvGenesetSurvivalComponent,
    DocSnvSurvivalComponent,
    GsdbComponent,
  ],
  imports: [CommonModule, MutationRoutingModule, SharedModule],
})
export class MutationModule {}
