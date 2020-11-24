import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MethylationComponent } from './methylation.component';

describe('MethylationComponent', () => {
  let component: MethylationComponent;
  let fixture: ComponentFixture<MethylationComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ MethylationComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MethylationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
